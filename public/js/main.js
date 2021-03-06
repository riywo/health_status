$(function () {
  $("div[rel='tooltip']").tooltip();

  $("#timezones").on('shown', function() {
    var modal_scrollpos = $("#timezones li.active:first").position().top - 250;
    $("#timezones .modal-body").scrollTop(modal_scrollpos);
  });

  $("#timezones").on('hide', function() {
    $("#timezones .modal-body").scrollTop(0);
  });

  $.cookie("timezone", $("#timezones li.active").data("timezone"));

  $("#timezones li").click(function () {
    $.cookie("timezone", $(this).data("timezone"));
  });

  $("div.service-accordion").on('show', function(event) {
    if ($(event.target).hasClass('service-accordion')) {
      $(this).find("div.application-row").each(function (i, e) {
        $(e).addClass("shown-row");
        update_row(i, e);
      });
      $(this).find("div.application-accordion.in").find("div.metric-row").each(function (i, e) {
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
      $(this).find("div.application-row").each(function () {
        $(this).removeClass("shown-row");
      });
      $(this).find("div.application-accordion.in").find("div.metric-row").each(function () {
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

  $("#refresh").click(refresh_rows);

  refresh_rows();

  setInterval(refresh_rows, 60000);

  function refresh_rows () {
    var url = "/api/v2/";
    $.getJSON(url, function(json) {
      var get_ids = [];
      for (var i = 0; i < json.length; i++) {
        var service = json[i];
        append_service($("#main-container"), service, "/api/v2", get_ids);
      }

      var old_ids = $("#main-container").data("ids");
      if (old_ids) {
        for (var i = 0; i < old_ids.length; i++) {
          if (get_ids.indexOf(old_ids[i]) == -1) {
            $(old_ids[i]).remove();
            $(old_ids[i]+"-accordion").remove();
          }
        }
      }

      $("#main-container").data("ids", get_ids);
      force_update_visible();
    });
  }

  function append_service (main, service, url, get_ids) {
    var service_row = $("#service-"+service.id);
    get_ids.push("#service-"+service.id);
    if (service_row.length == 0) {
      service_row = $("#service-ID").clone().attr("id", "service-"+service.id).removeClass("hide");
      service_row.data("url", url + "/" + encodeURIComponent(service.name));
      service_row.find("div.alert").data("title", service.name).tooltip();
      service_row.find("a.accordion-toggle").data("parent", "#service-"+service.id);
      service_row.find("a.accordion-toggle").attr("href", "#service-"+service.id+"-accordion");
      service_row.find("a.accordion-toggle strong").text(service.name);
      main.append(service_row);
    }
    append_applications_accordion(main, service, service_row.data("url"), get_ids);
  }

  function append_applications_accordion (main, service, url, get_ids) {
    var app_accordion = $("#service-"+service.id+"-accordion");
    if (app_accordion.length == 0) {
      app_accordion = $("#service-ID-accordion").clone(true).attr("id", "service-"+service.id+"-accordion").removeClass("hide");
      main.append(app_accordion);
    }
    for (var i = 0; i < service.applications.length; i++) {
      append_application(app_accordion, service.applications[i], url, get_ids);
    }
  }

  function append_application (app_accordion, application, url, get_ids) {
    var app_row = $("#application-"+application.id);
    get_ids.push("#application-"+application.id);
    if (app_row.length == 0) {
      app_row = $("#application-ID").clone().attr("id", "application-"+application.id).removeClass("hide");
      app_row.data("url", url + "/" + encodeURIComponent(application.name));
      app_row.find("div.alert").data("title", application.name).tooltip();
      app_row.find("a.accordion-toggle").data("parent", "#application-"+application.id);
      app_row.find("a.accordion-toggle").attr("href", "#application-"+application.id+"-accordion");
      app_row.find("a.accordion-toggle strong").text(application.name);
      app_accordion.append(app_row);
      if (app_accordion.hasClass("in")) {
        app_row.addClass("shown-row");
      }
    }
    append_metrics_accordion(app_accordion, application, app_row.data("url"), get_ids);
  }

  function append_metrics_accordion (app_accordion, application, url, get_ids) {
    var metric_accordion = $("#application-"+application.id+"-accordion");
    if (metric_accordion.length == 0) {
      metric_accordion = $("#application-ID-accordion").clone(true).attr("id", "application-"+application.id+"-accordion").removeClass("hide");
      app_accordion.append(metric_accordion);
    }
    for (var i = 0; i < application.metrics.length; i++) {
      append_metric(metric_accordion, application.metrics[i], url, get_ids);
    }
  }

  function append_metric (metric_accordion, metric, url, get_ids) {
    var metric_row = $("#metric-"+metric.id);
    get_ids.push("#metric-"+metric.id);
    if (metric_row.length == 0) {
      metric_row = $("#metric-ID").clone().attr("id", "metric-"+metric.id).removeClass("hide");
      metric_row.data("url", url + "/" + encodeURIComponent(metric.name));
      metric_row.find("div.alert").data("title", metric.name).tooltip();
      metric_row.find("div.alert").text(metric.name);
      metric_accordion.append(metric_row);
      if (metric_accordion.hasClass("in")) {
        metric_row.addClass("shown-row");
      }
    }
  }

  function force_update_visible () {
console.log("force_update_visible");
    $("div.container div.shown-row").each(force_update_row);
  }
  function update_visible () {
console.log("update_visible");
    $("div.container div.shown-row").each(update_row);
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
      var url   = row.data("url") + "?timezone=" + encodeURIComponent($.cookie("timezone"));
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
