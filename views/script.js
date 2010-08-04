// Copyright 2010, Westside Consulting LLC, Ann Arbor, MI, USA

$(document).ready(function() {
  var regxRow = /row(\d)/;
  var recxCol = /col(\d)/;

  $.extend({
    // returns array: [<row name>, <row number>, <col name>, <col number>]
    rowCol: function($el) {
      var klass = $el.attr('class');
      return regxRow.exec(klass).concat(recxCol.exec(klass));
    },
    setTileBackgroundColor: function($el, color) {
      var rowCol = $.rowCol($el);
      var rowName = rowCol[0];
      var colName = rowCol[2];
      var $target = $('.' + Array('cell', 'picture', rowName, colName).join('.'));
      $target.css('background-color', color);
    }
  });

  $.fn.extend({
  });

  $('.cell.checkmark').hover(
    function(ev) {
      $.setTileBackgroundColor($(this), 'red');
    },
    function(ev) {
      $.setTileBackgroundColor($(this), '');
    }
  );

  $('.cell').click(function() {
    var rowCol = $.rowCol($(this));
    var rowName = rowCol[0];
    var colName = rowCol[2];
    var $target = $('.' + Array('cell', 'checkmark', rowName, colName).join('.'));
    //alert($target.length);
    var checked = ($target.css('display') != 'none');
    $target.css({display: checked ? 'none' : 'block'});
  });
});
