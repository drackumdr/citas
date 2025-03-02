// Flutter web input element focus fix
(function() {
  // Fix for pointer binding issue with input elements
  let lastFocusedElement = null;
  let lastClickTime = 0;
  
  // Keep track of the last focused element
  document.addEventListener('focus', function(e) {
    if (e.target.tagName && 
        (e.target.tagName.toLowerCase() === 'input' || 
         e.target.tagName.toLowerCase() === 'textarea')) {
      lastFocusedElement = e.target;
    }
  }, true);
  
  // Handle clicks on the document
  document.addEventListener('click', function(e) {
    // Store current timestamp for debouncing
    lastClickTime = Date.now();
    
    // If clicked outside an input and an input has focus, blur it
    if (lastFocusedElement && 
        e.target !== lastFocusedElement &&
        e.target.tagName &&
        e.target.tagName.toLowerCase() !== 'input' &&
        e.target.tagName.toLowerCase() !== 'textarea') {
      lastFocusedElement.blur();
      lastFocusedElement = null;
    }
  }, true);
  
  // Patch the problematic Flutter web function
  window._flutter_web_patch = function() {
    // This will run after Flutter initialization
    if (window._flutter && window._flutter.loader && window._flutter.loader._scriptLoaded) {
      const originalComputeEventOffset = window._flutter_engine && 
                                        window._flutter_engine.computeEventOffsetToTarget;
      
      if (originalComputeEventOffset) {
        window._flutter_engine.computeEventOffsetToTarget = function(event, target) {
          try {
            return originalComputeEventOffset(event, target);
          } catch (e) {
            // If error contains the specific assertion message, return a fallback
            if (e.toString().includes("targetElement == domElement")) {
              console.log("Suppressed Flutter web pointer binding error");
              // Return a fallback position
              return { x: 0, y: 0 };
            }
            throw e;
          }
        };
      }
    }
  };
})();
