$(function () {

  $("#timezones").on('shown', function() {
    var modal_scrollpos = $("#timezones li.active:first").position().top - 250;
    $("#timezones .modal-body").scrollTop(modal_scrollpos);
  });

  $("#timezones").on('hide', function() {
    $("#timezones .modal-body").scrollTop(0);
  });

  $("div.service-accordion").on('shown', function(event) {
    if ($(event.target).hasClass('service-accordion')) {
      $(this).find("div.application-row, div.in").each(update_row);
      $(this).find("div.application-row, div.in").each(function () {
        $(this).addClass("shown-row");
      });
    }
  });

  $("div.application-accordion").on('shown', function(event) {
    if ($(event.target).hasClass('application-accordion')) {
      $(this).find("div.metric-row").each(update_row);
      $(this).find("div.metric-row").each(function () {
        $(this).addClass("shown-row");
      });
    }
  });

  $("div.service-accordion").on('hidden', function(event) {
    if ($(event.target).hasClass('service-accordion')) {
      $(this).find("div.application-row, div.in").each(function () {
        $(this).removeClass("shown-row");
      });
    }
  });

  $("div.application-accordion").on('hidden', function(event) {
    if ($(event.target).hasClass('application-accordion')) {
      $(this).find("div.metric-row").each(function () {
        $(this).removeClass("shown-row");
      });
    }
  });

  $("div.shown-row").each(update_row);
  setInterval(function () {
    $("div.shown-row").each(update_row);
  }, 60000);


  function titleClass (status) {
    switch (status) {
      case 1:
        return "alert-success"; break;
      case 2:
        return ""; break;
      case 3:
        return "alert-error"; break;
      default:
        return "alert-info"; break;
    }
  }

  function labelClass (status) {
    switch (status) {
      case 1:
        return "label-success"; break;
      case 2:
        return "label-warning"; break;
      case 3:
        return "label-important"; break;
      default:
        return ""; break;
    }
  }

  function update_row () {
    var refresh_time = $(this).data("refresh_time") ? $(this).data("refresh_time") : 0;
    var now = Math.round(+new Date()/1000);
    if (refresh_time < now - 20) {
      $(this).data("refresh_time", now);
      var url   = $(this).data("url");
      var title = $(this).find(".alert");
      var hours = $(this).find(".status-hourly span");
      var days  = $(this).find(".status-daily span");
      $.getJSON(url, function(json) {
        title.each(function (){
          $(this).removeClass("alert-success alert-error alert-info").addClass(titleClass(json.current_status));
        });

        for (var i = 0; i < 25; i++) {
          var data = json.hourly_status[24-i];
          var span = $(hours.get(i));
          span.text(parse_hour(data.datetime));
          span.removeClass("label-success label-warning label-important").addClass(labelClass(data.status));
        }

        for (var i = 0; i < 8; i++) {
          var data = json.daily_status[7-i];
          var span = $(days.get(i));
          span.text(parse_date(data.datetime));
          span.removeClass("label-success label-warning label-important").addClass(labelClass(data.status));
        }
      });
    }
  }

  function parse_hour (datetime) {
    var m = datetime.match(/^\d{4}-\d{2}-\d{2}T(\d{2}):\d{2}:\d{2}/);
    return m[1];
  }

  function parse_date (datetime) {
    var m = datetime.match(/^\d{4}-(\d{2})-(\d{2})T\d{2}:\d{2}:\d{2}/);
    return m[1] + "/" + m[2];
  }

});
