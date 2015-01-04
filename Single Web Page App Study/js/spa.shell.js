/*
 * spa.shell.js
 * Shell Module for SPA
 */
 
/* JSLint         browser : true, continue : true,
   devel  : true, indent  : 2,    maxerr   : 50,
   newcap : true, nomen   : true, plusplus : true,
   regexp : true, sloppy  : true, vars     : false,
   white  : true
*/
/*global $, spa */
spa.shell = (function () {
  //----------------- BEGIN Module Scope Variables --------
  var
    configMap = {
      main_html : String()
        + '<div class="spa-shell-head">'
          + '<div class="spa-shell-head-logo"></div>'
          + '<div class="spa-shell-head-acct"></div>'
          + '<div class="spa-shell-head-search"></div>'
        + '</div>'
        + '<div class="spa-shell-main">'
          + '<div class="spa-shell-main-nav"></div>'
          + '<div class="spa-shell-main-content"></div>'
        + '</div>'
        + '<div class="spa-shell-foot"></div>'
        + '<div class="spa-shell-chat"></div>'
        + '<div class="spa-shell-modal"></div>'
    },
    stateMap = {$container : null},
    jqueryMap = {},
    
    setJqueryMap, initModule;
  //----------------- END MODULE SCOPE VARIABLES ---------------
  
  //----------------- BEGIN UTILITY METHODS --------------------
  //------------------ END UTILITY METHODS ---------------------
  
  //------------------- BEGIN DOM METHODS ----------------------
  setJqueryMap = function () {
    var $container = stateMap.$container;
    jqueryMap = { $container : $container };
  };
  //-------------------- END DOM METHODS -----------------------

  //------------------ BEGIN EVENT HANDLERS --------------------
  //------------------- END EVENT HANDLERS ---------------------

  //------------------ BEGIN PUBLIC METHODS --------------------
  initModule = function( $container ) {
    stateMap.$container = $container,
    $container.html( configMap.main_html );
    setJqueryMap();
  };
  return { initModule : initModule };
  //------------------- END PUBLIC METHODS ---------------------
}());
