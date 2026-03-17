-- Audio System - Procedural SFX Generation

local audio = {}
audio.enabled = true
audio.musicEnabled = true
audio.sfx = {}
audio.musicPlaylist = {}
audio.currentTrack = nil
audio.currentTrackIndex = 0
audio.wasPausedByToggle = false
audio.musicVolume = 0.105

function audio.initMusic()
    local files = love.filesystem.getDirectoryItems("src/audio/music")
    for _, file in ipairs(files) do
        if file:match("%.ogg$") then
            local source = love.audio.newSource("src/audio/music/" .. file, "stream")
            source:setVolume(audio.musicVolume)
            table.insert(audio.musicPlaylist, source)
        end
    end
    audio.shuffleMusic()
end

function audio.shuffleMusic()
    for i = #audio.musicPlaylist, 2, -1 do
        local j = love.math.random(i)
        audio.musicPlaylist[i], audio.musicPlaylist[j] = audio.musicPlaylist[j], audio.musicPlaylist[i]
    end
end

function audio.update()
    if not audio.musicEnabled then
        if audio.currentTrack and audio.currentTrack:isPlaying() then
            audio.currentTrack:pause()
            audio.wasPausedByToggle = true
        end
        return
    end
    
    if #audio.musicPlaylist == 0 then return end
    
    if not audio.currentTrack then
        audio.nextTrack()
    else
        audio.currentTrack:setVolume(audio.musicVolume) -- Keep volume in sync
        if not audio.currentTrack:isPlaying() then
            if audio.wasPausedByToggle then
                audio.currentTrack:play()
                audio.wasPausedByToggle = false
            else
                audio.nextTrack()
            end
        end
    end
end

function audio.nextTrack()
    if audio.currentTrack then
        audio.currentTrack:stop()
    end
    audio.currentTrackIndex = audio.currentTrackIndex + 1
    if audio.currentTrackIndex > #audio.musicPlaylist then
        audio.shuffleMusic()
        audio.currentTrackIndex = 1
    end
    audio.currentTrack = audio.musicPlaylist[audio.currentTrackIndex]
    if audio.currentTrack then
        audio.currentTrack:setVolume(audio.musicVolume)
        audio.currentTrack:play()
    end
end

function audio.generateSFX()
    local rate = 44100
    
    local function gen(duration, generator)
        local samples = math.floor(rate * duration)
        local data = love.sound.newSoundData(samples, rate, 16, 1)
        generator(samples, rate, data)
        return love.audio.newSource(data)
    end

    local function noise() return math.random() * 2 - 1 end

    -- 1. Pickup: A modern, satisfying "pop" (fast downward pitch sweep + bright transient)
    audio.sfx.pickup = gen(0.12, function(samples, rate, data)
        local phase = 0
        for i = 0, samples - 1 do
            local t = i / rate
            
            -- Pitch envelope: starts very high, drops exponentially fast (the classic pop)
            local freq = 300 + 1200 * math.exp(-t * 200)
            phase = phase + freq / rate
            
            local env = math.exp(-t * 35)
            local s = math.sin(phase * math.pi * 2) * env
            
            -- Add a crisp snap at the very beginning
            local snapEnv = math.exp(-t * 600)
            local snap = noise() * snapEnv * 0.4
            
            data:setSample(i, (s * 0.8 + snap) * 0.6)
        end
    end)

    -- 2. Drop: Deep, premium "thock" (Heavy sub-bass + wood knock)
    audio.sfx.drop = gen(0.18, function(samples, rate, data)
        local subPhase, midPhase = 0, 0
        for i = 0, samples - 1 do
            local t = i / rate
            
            -- Sub-layer: deep weighty punch
            local subFreq = 40 + 200 * math.exp(-t * 80)
            subPhase = subPhase + subFreq / rate
            local subEnv = math.exp(-t * 22)
            local sub = math.sin(subPhase * math.pi * 2) * subEnv
            
            -- Mid-layer: wooden / plastic knock
            local midFreq = 300 + 500 * math.exp(-t * 150)
            midPhase = midPhase + midFreq / rate
            local midEnv = math.exp(-t * 40)
            -- slightly squarish for a knock character
            local mid = (math.sin(midPhase * math.pi * 2) + math.sin(midPhase * math.pi * 6) * 0.3) * midEnv
            
            -- Click transient
            local clickEnv = math.exp(-t * 800)
            local click = noise() * clickEnv * 0.6
            
            data:setSample(i, (sub * 0.7 + mid * 0.4 + click) * 0.6)
        end
    end)

    -- 3. Error: Smooth, soft, modern "dud"
    audio.sfx.error = gen(0.2, function(samples, rate, data)
        local phase1, phase2 = 0, 0
        for i = 0, samples - 1 do
            local t = i / rate
            local pitchEnv = math.exp(-t * 3) -- very slight pitch drift down
            phase1 = phase1 + (110 * pitchEnv) / rate
            phase2 = phase2 + (115 * pitchEnv) / rate
            
            local env = math.exp(-t * 20)
            -- Apply a slight low-pass effect roughly via math
            local s = (math.sin(phase1 * math.pi * 2) + math.sin(phase2 * math.pi * 2)) * 0.5 * env
            
            -- Attack envelope to remove initial click
            local attack = math.min(1, t / 0.005)
            
            data:setSample(i, s * attack * 0.7)
        end
    end)

    -- 4. Clear: Premium cascading "gem/sparkle" sweep
    audio.sfx.clear = gen(1.5, function(samples, rate, data)
        local steps = {0, 4, 7, 11, 14, 19, 23} -- Lydian/Maj9 spread
        local phases = {0,0,0,0,0,0,0}
        
        for i = 0, samples - 1 do
            local t = i / rate
            local s = 0
            
            -- Speed of the sweep
            local speed = 25
            local currentStep = math.floor(t * speed)
            
            for j, note in ipairs(steps) do
                -- Only play notes that have been triggered in the sweep sequence
                if currentStep >= (j - 1) then
                    local noteTime = t - ((j - 1) / speed)
                    local freq = 440 * math.pow(1.05946, note + 5) -- Base pitch shifted up
                    
                    phases[j] = phases[j] + freq / rate
                    
                    -- Bell-like envelope: fast attack, exponential decay
                    local env = math.exp(-noteTime * 6)
                    
                    -- Pure sine wave with a hint of FM for metallic shine
                    local mod = math.sin(phases[j] * math.pi * 5.6) * 0.3 * env
                    local tone = math.sin((phases[j] + mod) * math.pi * 2)
                    
                    s = s + tone * env * (1.5 / j) -- Higher notes are slightly quieter
                end
            end
            
            -- Soften attack over entire sound
            local masterEnv = math.min(1, t / 0.01) * math.exp(-t * 0.8)
            data:setSample(i, s * masterEnv * 0.3)
        end
    end)

    -- 5. Gameover: Thick, descending drone ("womp womp")
    audio.sfx.gameover = gen(2.0, function(samples, rate, data)
        local p1, p2, p3 = 0, 0, 0
        for i = 0, samples - 1 do
            local t = i / rate
            -- Steeper pitch drop
            local freq = 300 * math.exp(-t * 1.5)
            p1 = p1 + freq / rate
            p2 = p2 + (freq * 0.98) / rate -- Detune for thickness
            p3 = p3 + (freq * 1.02) / rate
            
            local env = math.exp(-t * 2)
            -- slightly squarish
            local s1 = math.sin(p1 * math.pi * 2) + math.sin(p1 * math.pi * 6) * 0.2
            local s2 = math.sin(p2 * math.pi * 2)
            local s3 = math.sin(p3 * math.pi * 2)
            
            local s = (s1 + s2 + s3) / 3 * env
            data:setSample(i, s * 0.4)
        end
    end)

    -- 6. UI Click: High-quality, crisp "snick"
    audio.sfx.ui_click = gen(0.04, function(samples, rate, data)
        local phase = 0
        for i = 0, samples - 1 do
            local t = i / rate
            -- High pitch sweep for a sharp tick
            local freq = 2000 * math.exp(-t * 200)
            phase = phase + freq / rate
            local env = math.exp(-t * 150)
            local tone = math.sin(phase * math.pi * 2) * env
            local nz = noise() * env * 0.5
            data:setSample(i, (tone + nz) * 0.4)
        end
    end)
end

function audio.playSFX(name, pitch, volume)
    if audio.enabled and audio.sfx[name] then
        local sound = audio.sfx[name]:clone()
        if pitch then sound:setPitch(pitch) end
        if volume then sound:setVolume(volume) end
        sound:play()
    end
end

function audio.loadSettings()
    if love.filesystem.getInfo("block_audio.txt") then
        local data = love.filesystem.read("block_audio.txt")
        if data then
            -- Parse key=value format
            for line in data:gmatch("[^\r\n]+") do
                local key, value = line:match("([^=]+)=(.+)")
                if key and value then
                    key = key:match("^%s*(.-)%s*$")  -- Trim whitespace
                    value = value:match("^%s*(.-)%s*$")  -- Trim whitespace
                    
                    if key == "enabled" then
                        audio.enabled = (value == "true")
                    elseif key == "musicEnabled" then
                        audio.musicEnabled = (value == "true")
                    elseif key == "musicVolume" then
                        local vol = tonumber(value)
                        if vol then
                            audio.musicVolume = math.max(0, math.min(1, vol))  -- Clamp to 0-1
                        end
                    end
                end
            end
        end
    end
end

function audio.saveSettings()
    local lines = {}
    table.insert(lines, "enabled=" .. tostring(audio.enabled))
    table.insert(lines, "musicEnabled=" .. tostring(audio.musicEnabled))
    table.insert(lines, "musicVolume=" .. tostring(audio.musicVolume))
    
    love.filesystem.write("block_audio.txt", table.concat(lines, "\n"))
end

return audio
