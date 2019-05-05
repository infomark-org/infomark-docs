$(function() {


    "use strict";

    var wind = $(window);

    if (!$("body").hasClass("switch-nav")) {
        $(".navbar").removeClass("nav-scroll");
    }

    var $el = $('#main'); //record the elem so you don't crawl the DOM everytime

    wind.on("scroll", function() {

        var bodyScroll = wind.scrollTop(),
            navbar = $(".navbar");
        // navbloglogo = $(".blog-nav .logo> img"),
        // logo = $(".navbar .logo> img");
        // console.log(bodyScroll);
        if ($("body").hasClass("switch-nav")) {
            if (bodyScroll > $el.position().top - 60) {

                navbar.removeClass("nav-scroll");
                // logo.attr('src', 'img/logo-dark.png');

            } else {

                navbar.addClass("nav-scroll");
                // logo.attr('src', 'img/logo-light.png');
                // navbloglogo.attr('src', 'img/logo-dark.png');
            }
        }
    });
});