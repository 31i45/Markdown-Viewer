// Neutralinojs desktop app entry point for Markdown Viewer

function onWindowClose() {
  Neutralino.app.exit();
}

// Handle file from command line argument
(function() {
  function tryLoad() {
    if (typeof window.openFile !== 'function') {
      setTimeout(tryLoad, 200);
      return;
    }
    // Get command line args via multiple strategies
    findAndLoadFile();
  }

  async function findAndLoadFile() {
    var filePath = null;

    // Strategy 1: Check NL_ARGS global variable
    var args = [];
    if (typeof NL_ARGS !== 'undefined') {
      if (Array.isArray(NL_ARGS)) {
        args = NL_ARGS;
      } else if (typeof NL_ARGS === 'string') {
        try { args = JSON.parse(NL_ARGS); } catch(e) {}
      }
    }
    for (var i = 0; i < args.length; i++) {
      if (typeof args[i] === 'string' && /\.(md|markdown)$/i.test(args[i])) {
        filePath = args[i];
        break;
      }
    }

    // Strategy 2: If NL_ARGS didn't contain the file path,
    // use PowerShell to get the actual process command line
    if (!filePath) {
      try {
        var result = await Neutralino.os.execCommand(
          'powershell -Command "(Get-CimInstance Win32_Process -Filter \\"ProcessId=$PID\\").CommandLine"'
        );
        var cmdLine = (result.stdOut || '').trim();
        // Parse the command line to find .md file path
        var parts = cmdLine.match(/"[^"]+"|\S+/g) || [];
        for (var j = 0; j < parts.length; j++) {
          var part = parts[j].replace(/^"|"$/g, '');
          if (part && /\.(md|markdown)$/i.test(part)) {
            filePath = part;
            break;
          }
        }
      } catch(e) {
        console.error('[main.js] Failed to get command line:', e.message);
      }
    }

    if (!filePath) {
      console.log('[main.js] No .md file found in command line');
      return;
    }

    console.log('[main.js] Found .md file:', filePath);

    var fileName = filePath.split(/[/\\]/).pop().replace(/\.(md|markdown)$/i, '');
    Neutralino.filesystem.readFile(filePath)
      .then(function(content) {
        console.log('[main.js] File loaded, calling openFile:', fileName);
        window.openFile(content, fileName);
      })
      .catch(function(e) {
        console.error('[main.js] Failed to read file:', e.message);
      });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
      setTimeout(tryLoad, 300);
    });
  } else {
    setTimeout(tryLoad, 300);
  }
})();

// Initialize Neutralino
Neutralino.init();

// Register event listener
Neutralino.events.on("windowClose", onWindowClose);
