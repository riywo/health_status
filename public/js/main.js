$(function () {
  $("div[rel='tooltip']").tooltip();

  $("#timezones").on('shown', function() {
    var modal_scrollpos = $("#timezones li.active:first").position().top - 250;
    $("#timezones .modal-body").scrollTop(modal_scrollpos);
  });

  $("#timezones").on('hide', function() {
    $("#timezones .modal-body").scrollTop(0);
  });

  $("div.service-accordion").on('show', function(event) {
    if ($(event.target).hasClass('service-accordion')) {
      $(this).find("div.application-row, div.in").each(function (i, e) {
        $(e).addClass("shown-row");
        update_row(i, e);
      });
    }
  });

  $("div.application-accordion").on('show', function(event) {
    if ($(event.target).hasClass('application-accordion')) {
      $(this).find("div.metric-row").each(function (i, e) {
        $(e).addClass("shown-row");
        update_row(i, e);
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

  $("#refresh").click(force_update_visible);

  force_update_visible();
  setInterval(force_update_visible, 60000);

  function force_update_visible () {
console.log("force_update_visible");
    $("div.shown-row").each(force_update_row);
  }
  function update_visible () {
console.log("update_visible");
    $("div.shown-row").each(update_row);
  }

  function force_update_row (index, element) {
    $(element).data("refresh_time", 0);
    update_row(index, element);
  }

  function update_row (index, element) {
    var row = $(element);
    var refresh_time = row.data("refresh_time") === undefined ? 0 : row.data("refresh_time");
    var now = Math.round(+new Date()/1000);
    if (refresh_time < now - 60) {
      row.data("refresh_time", now);
console.log("update " + row.attr("id") + " time: " + row.data("refresh_time"));
      var url   = row.data("url");
      var title = row.find(".alert");
      var hours = row.find(".status-hourly span");
      var days  = row.find(".status-daily span");
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
    } else {
console.log("skip update " + row.attr("id") + " time: " + refresh_time + " now: " + now);
    }
  }

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

  function parse_hour (datetime) {
    var m = datetime.match(/^\d{4}-\d{2}-\d{2}T(\d{2}):\d{2}:\d{2}/);
    return m[1];
  }

  function parse_date (datetime) {
    var m = datetime.match(/^\d{4}-(\d{2})-(\d{2})T\d{2}:\d{2}:\d{2}/);
    return m[1] + "/" + m[2];
  }

});
