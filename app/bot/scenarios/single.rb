module Bot
  module Scenarios
    module Single
      def single_scenario link = query
        scroll_percent = config.scroll_height_link ||
                         config.scroll_height_non_target
        log(:link, "прокрутка #{scroll_percent}%")
        Thread.new do
          driver.navigate.to(link)
        end
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

      def right_clicks_scenario
        q, site, amount = query.split("/")
        right_clicks = []
        search q
        r = search_results.reduce do |_, s|
          break s if s.text.match? Regexp.new site
        end
        return log(:error, "Нет подходящего сайта") unless r

        amount.to_i.times do
          driver.action.context_click(r.find_element(css: "a")).perform
          right_clicks << r.find_element(css: "a").attribute(:href)
          sleep 1
        end

        ua = driver.js "return navigator.userAgent"
        driver.quit
        right_clicks.each do |link|
          core.driver = Driver.new core, user_agent: ua
          single_scenario link
          wait :links_delay
          driver.quit
        end
      end
    end
  end
end
