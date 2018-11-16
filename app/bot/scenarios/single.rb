module Bot
  module Scenarios
    module Single
      def single_scenario link = query
        scroll_percent = config.scroll_height_link ||
                         config.scroll_height_non_target
        log(:link, "прокрутка #{scroll_percent}%")
        driver.navigate.to(link)
        wait config.pre_delay_link
        return if scroll_percent.nil? || scroll_percent.zero?
        wait 10
        driver.js "window.stop()"
        print "  "
        scroll while (driver.scroll_height * 0.01 * scroll_percent) > driver.y_offset
        puts
      end

      def additional_visits
        unless config.additional_visits&.empty?
          config.additional_visits.each do |link|
            single_scenario link
          end
        end
      end
    end
  end
end
