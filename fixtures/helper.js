(function(init) {
  if (location.hash === '#noscript')
    return;

  var readyState = document.readyState;
  if (readyState === 'complete') {
    init();
  } else {
    document.addEventListener("DOMContentLoaded", init, false);
  }
  window.addEventListener("load", init, false);
})(function init() {
  if (document.getElementById('nav'))
    return;

  var style = document.createElement('style');
  style.setAttribute('type', 'text/css');
  style.innerHTML = '#nav { background: #002b36; color: #839496; margin: -3px 0 3px -7px ; padding: 5px; } ' + 
    '#nav a { color: #839496; text-decoration: none; } ' +
    '#nav .sep { color: #657b83; }';
  document.head.appendChild(style);

  var nav = document.createElement('div');
  nav.setAttribute('id', 'nav');
  nav.innerHTML = '<a href="/t/console">console</a> <span class="sep">|</span> <a href="/t/server">server</a> <span class="sep">|</span> <a href="/t/channel">channel</a> <span class="sep">/</span> <span id="selector"></span>'
  document.body.insertBefore(nav, document.body.firstChild);

  function debounce(fn) {
    var timeout;
    function wrapper() {
      var args = arguments;
      if (timeout)
        clearTimeout(timeout)
      timeout = setTimeout(function() {
        fn.apply(fn, args);
      }, 100);
    }
    return wrapper
  }

  function getSelector(el) {
    function recurse(el) {
      var tag = el.tagName.toLowerCase(),
        id = el.id ? '#' + el.id : '',
        cls = el.className ? '.' + el.className.split(' ').join('.') : '',
        type = el.getAttribute('type');
      type = type ? '[type=' + type + ']' : '';
      return (el.parentElement ? recurse(el.parentElement) : '') + (' ' + tag + id + cls + type);
    }
    return recurse(el);
  }

  function showSelector(e) {
    document.getElementById('selector').innerHTML = getSelector(e.target);
  }

  document.addEventListener('mouseover', showSelector);

  var es = new EventSource('/eventsource')
  es.onerror = function(e) {
    console.log('err:', e);
  };
    
  es.addEventListener('reload', function() {
    console.log('reloading');
    location.reload();
  });
})

