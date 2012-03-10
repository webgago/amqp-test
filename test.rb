require "bundler/setup"
require 'amqp'
require 'amqp/utilities/event_loop_helper'
require "bench_press"
require "httparty"

extend BenchPress
$i = 0

AMQP::Utilities::EventLoopHelper.run do
  AMQP.start

  exchange = AMQP.channel.fanout("amq.fanout")

  q = AMQP.channel.queue("soap", :durable => true, :auto_delete => false)
  q.bind(exchange)
  exchange.publish("Started!", :routing_key => q.name)
end

measure "HTTParty" do
  $i += 1
  HTTParty.get "http://localhost:4567/?msg=#{$i}"
end

measure "AMQP" do
  e = AMQP.channel.fanout("amq.fanout")
  q = AMQP.channel.queue("soap", :durable => true, :auto_delete => false)
  q.bind(e)

  e.publish("#{$i} at (#{Time.now.to_i})", :persistent => true, :routing_key => q.name)
end
