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

  // Got it from http://docs.jquery.com/Blink
  var doBlink = function(obj, start, finish) {
    jQuery(obj).fadeOut(300).fadeIn(300);

    if(start!=finish) {
      start=start+1;
      doBlink(obj,start,finish);
    }
  } 

  $.fn.extend({
    blink: function(start, finish) {
      return this.each(function() {
        doBlink(this,start,finish)
      });
    }
  });

  $('.cell.checkmark').hover(
    function(ev) { // mouse enter
      $.setTileBackgroundColor($(this), 'red');
    },
    function(ev) { // mouse exit
      $.setTileBackgroundColor($(this), '');
    }
  );

  $('.cell').click(function() {
    var id        = $('#card-id').attr('value');
    var rowCol    = $.rowCol($(this));
    var rowName   = rowCol[0];
    var rowNum    = rowCol[1];
    var colName   = rowCol[2];
    var colNum    = rowCol[3];
    var $target = $('.' + Array('cell', 'checkmark', rowName, colName).join('.'));
    //console.log("rowCol=" + rowCol);
    //console.log("$target.len=" + $target.length);

    $target.toggleClass("on");

    jQuery.ajax({
      type: 'PUT',
      url: "/cards/" + id,
      data: {
        row: rowNum,
        col: colNum,
        covered: $target.hasClass('on') ? "true" : "false"
      },
      context: $target,
      success: function(data, textStatus, XMLHttpRequest) {
        var hasBingo = XMLHttpRequest.getResponseHeader('X-Busbingo-Has-Bingo');
        //console.log("hasBingo=" + hasBingo);

        if (hasBingo === "true") {
          $('#you-have-bingo').addClass('on');
          $('#you-have-bingo-inside').blink(1,4);
        } else {
          $('#you-have-bingo').removeClass('on');
        }
      },
      error: function(XMLHttpRequest, textStatus, errorThrown) {
        // Reverse the user's click.
        $(this).toggleClass("on");

        if (console && console.log) {
          console.log('An error occurred: ' + errorThrown + ', status=' + textStatus);
        }
      }
    });
    return false;
  });
});
