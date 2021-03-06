module Mnemosyne
  class Sweeper
    include Helper

    def initialize(port, config, status, logger)
      @status = status
      @config = config
      @logger = logger
    end

    def run
      if @config.empty?
        puts "Please specify a valid mneme configuration file (ex: -c config.rb)"
        EM.stop
        exit
      end

      sweeper = Proc.new do
        Fiber.new do
          current = epoch_name(@config['namespace'], 0, @config['length'])
          @logger.info "Sweeping old filters, current epoch: #{current}"

          conn = Redis.new
          @config['periods'].times do |n|
            name = epoch_name(@config['namespace'], n + @config['periods'], @config['length'])

            conn.del(name)
            @logger.info "Removed: #{name}"
          end
          conn.client.disconnect
        end.resume
      end

      sweeper.call
      EM.add_periodic_timer(@config['length']) { sweeper.call }

      @logger.info "Started Mnemosyne::Sweeper with #{@config['length']}s interval"
    end
  end
end
