# frozen_string_literal: true

module Xseed
  module Documentation
    module Presentation
      # Generates JavaScript code for HTML documentation
      # Ports functionality from XS3P javascript.xsl
      class JavascriptGenerator
        NAV_WIDTH = "298px"

        def initialize(config)
          @config = config
        end

        def generate
          <<~JAVASCRIPT
            // XSD Documentation JavaScript
            // Ported from XS3P javascript.xsl

            document.addEventListener('DOMContentLoaded', function() {
              // TOC toggle
              initializeTOC();

              // Tooltips and popovers
              initializeTooltips();

              // Smooth scrolling
              initializeSmoothScroll();

              // Bootstrap initialization
              initializeBootstrap();

              // Markdown processing
              initializeMarkdown();

              // Sidebar scrolling
              initializeSidebarScrolling();
            });

            function initializeTOC() {
              var duration = 400;
              $('#toggle').on('click', function(){
                if( $('nav').is(':visible') ) {
                  $('nav').animate({ 'left': '-353px' }, duration, function(){
                    $('nav').hide();
                  });
                  $('body').animate({ 'margin-left': '0' }, duration);
                  $('#toggle > span').text('>');
                }
                else {
                  $('nav').show();
                  $('nav').animate({ 'left': '0px' }, duration);
                  $('body').animate({ 'margin-left': '#{NAV_WIDTH}' }, duration);
                  $('#toggle > span').text('<');
                }
              });
            }

            function initializeTooltips() {
              $("[data-toggle='tooltip']").tooltip();
            }

            function initializeSmoothScroll() {
              // Smooth scrolling for anchor links
              $('a[href^="#"]').on('click', function(e) {
                var target = $(this.getAttribute('href'));
                if (target.length) {
                  e.preventDefault();
                  $('html, body').stop().animate({
                    scrollTop: target.offset().top - 65
                  }, 500);
                }
              });
            }

            function initializeBootstrap() {
              // Initialize popovers
              $("[data-toggle='popover']").popover({ trigger: "hover" });

              // Modal handling
              $("[data-toggle='modal']").click(function() { return false; });

              $("[data-toggle='modal']").popover({
                trigger: "hover",
                html: true,
                content: function () {
                  var targetId = $(this).attr('data-target');
                  return $(targetId).html();
                }
              });
            }

            function initializeMarkdown() {
              if (typeof Markdown !== 'undefined' && Markdown.Converter) {
                var c = new Markdown.Converter();
                $('.xs3p-doc').each(function(i, obj) {
                  var rawDocID = '#' + $(this).attr('id') + '-raw';
                  var indent = $(rawDocID).html().match("^\\n[\\t ]*");
                  var normalized;
                  if (!(indent === null)) {
                    normalized = $(rawDocID).html().replace(new RegExp(indent[0], "gm"), "\\n");
                  } else {
                    normalized = $(rawDocID).html();
                  }
                  $(this).html(c.makeHtml(normalized));
                  $(this).find('code,pre').each(function(i, block) {
                    $(this).html($(this).text());
                  });
                });
              }
            }

            function initializeSidebarScrolling() {
              $(window).scroll(function() {
                if ($(".xs3p-sidebar").css("position") == "fixed" && $(window).height() < $(".xs3p-sidebar").height()) {
                  var perc = $(window).scrollTop() / $("#xs3p-content").height();
                  var overflow = $(".xs3p-sidebar").height() + 105 - $(window).height();
                  $(".xs3p-sidebar").css("top", (65 - Math.round(overflow * perc)) + "px");
                }
              });

              $(window).resize(function() {
                if ($(".xs3p-sidebar").css("position") == "fixed") {
                  $(".xs3p-sidebar").css("top", "65px");
                }
              });
            }
          JAVASCRIPT
        end

        def jquery_url
          @config.jquery_url || default_jquery_url
        end

        def bootstrap_url
          @config.bootstrap_url || default_bootstrap_url
        end

        private

        def default_jquery_url
          "https://cdnjs.cloudflare.com/ajax/libs/jquery/2.2.4/jquery.min.js"
        end

        def default_bootstrap_url
          "https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/3.4.1"
        end
      end
    end
  end
end
