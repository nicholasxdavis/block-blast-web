// Build script for love.js compilation
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('Building Block Blast for Web...\n');

const webDir = path.join(__dirname, 'web');
const loveFile = path.join(__dirname, 'game.love');

// Create web directory
if (!fs.existsSync(webDir)) {
    fs.mkdirSync(webDir, { recursive: true });
}

// Create .love file
console.log('Creating .love file...');
try {
    const archiver = require('archiver');
    const output = fs.createWriteStream(loveFile);
    const archive = archiver('zip', { zlib: { level: 9 } });
    
    return new Promise((resolve, reject) => {
        output.on('close', () => {
            console.log(`✓ Created ${loveFile} (${archive.pointer()} bytes)\n`);
            
            // Build with love.js
            console.log('Compiling with love.js...\n');
            const lovejsPath = path.join(__dirname, 'node_modules', 'love.js', 'index.js');
            
            if (!fs.existsSync(lovejsPath)) {
                console.error('ERROR: love.js not found! Run: npm install');
                process.exit(1);
            }
            
            // Use 200MB memory (assets are ~187MB) and compatibility mode (no SharedArrayBuffer)
            const buildCommand = `node "${lovejsPath}" -t "Block Blast" -m 209715200 -c "${loveFile}" "${webDir}"`;
            
            try {
                execSync(buildCommand, { stdio: 'inherit', cwd: __dirname, shell: true });
                
                // Fix WASM loading path and remove branding in index.html
                const indexPath = path.join(webDir, 'index.html');
                if (fs.existsSync(indexPath)) {
                    let html = fs.readFileSync(indexPath, 'utf8');
                    // Add locateFile function if not present
                    if (!html.includes('locateFile')) {
                        html = html.replace(
                            'INITIAL_MEMORY: 209715200,',
                            `INITIAL_MEMORY: 209715200,
        locateFile: function(path) {
          if (path.endsWith('.wasm')) {
            return './love.wasm';
          }
          return path;
        },`
                        );
                    }
                    // Remove love.js branding footer
                    html = html.replace(/<footer>[\s\S]*?<\/footer>/gi, '');
                    html = html.replace(/Built with[\s\S]*?love\.js[\s\S]*?<\/p>/gi, '');
                    // Remove loading screen branding
                    html = html.replace(/loadingContext\.fillText\("Powered By Emscripten\."[\s\S]*?loadingContext\.fillText\("Powered By LÖVE\."[\s\S]*?\);/gi, '');
                    // Remove title (h1)
                    html = html.replace(/<h1>.*?<\/h1>/gi, '');
                    html = html.replace(/<center>[\s]*<div>[\s]*<h1>.*?<\/h1>/gi, '');
                    html = html.replace(/<\/div>[\s]*<\/center>/gi, '');
                    // Make canvas fullscreen
                    if (!html.includes('FullScreenHook')) {
                        html = html.replace(
                            /function FullScreenHook\(\)\{[\s\S]*?\}/,
                            `function FullScreenHook(){
        var canvas = document.getElementById("canvas");
        var loadingCanvas = document.getElementById("loadingCanvas");
        var width = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth;
        var height = window.innerHeight || document.documentElement.clientHeight || document.body.clientHeight;
        canvas.width = width;
        canvas.height = height;
        loadingCanvas.width = width;
        loadingCanvas.height = height;
      }
      
      // Make fullscreen on load and resize
      window.addEventListener('load', function() {
        FullScreenHook();
      });
      window.addEventListener('resize', function() {
        FullScreenHook();
      });`
                        );
                    }
                    fs.writeFileSync(indexPath, html, 'utf8');
                    
                    // Update CSS to make fullscreen
                    const cssPath = path.join(webDir, 'theme', 'love.css');
                    if (fs.existsSync(cssPath)) {
                        const fullscreenCSS = `* {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
}

html, body {
    width: 100%;
    height: 100%;
    overflow: hidden;
    margin: 0;
    padding: 0;
}

body {
    background-color: #000;
    font-family: arial;
}

#loadingCanvas, #canvas {
    position: absolute;
    top: 0;
    left: 0;
    width: 100vw;
    height: 100vh;
    display: block;
    border: 0px none;
    padding: 0;
    margin: 0;
}

#canvas {
    visibility: hidden;
}

#loadingCanvas {
    visibility: visible;
}
`;
                        fs.writeFileSync(cssPath, fullscreenCSS, 'utf8');
                    }
                    
                    console.log('✓ Fixed WASM path, removed branding, and made fullscreen');
                }
                
                console.log('\n✓ Build completed successfully!');
                console.log(`\nOutput: ${webDir}`);
                console.log('\nRun: npm run serve');
                console.log('Then open: http://localhost:8080');
                resolve();
            } catch (error) {
                console.error('\n✗ Build failed!');
                process.exit(1);
            }
        });
        
        archive.on('error', reject);
        archive.pipe(output);
        
        // Add all .lua files
        const luaFiles = fs.readdirSync(__dirname).filter(f => f.endsWith('.lua') && f !== 'web_compat.lua');
        luaFiles.forEach(file => {
            archive.file(path.join(__dirname, file), { name: file });
        });
        
        // Add directories
        if (fs.existsSync(path.join(__dirname, 'src'))) {
            archive.directory(path.join(__dirname, 'src'), 'src');
        }
        if (fs.existsSync(path.join(__dirname, 'font'))) {
            archive.directory(path.join(__dirname, 'font'), 'font');
        }
        
        archive.finalize();
    });
} catch (error) {
    console.error('Build failed:', error.message);
    process.exit(1);
}
