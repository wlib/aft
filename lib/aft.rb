#!/usr/bin/env ruby
require "aft/version"
require 'socket'
require 'zlib'
require 'tempfile'

module Aft
  # A loading animation
  def loading(fps=10)
    chars = %w[| / - \\]
    delay = 1.0/fps
    go = true
    i = 0
    spinner = Thread.new do
      while go do
        print chars[(i+=1) % chars.length]
        sleep delay
        print "\b"
      end
    end
    yield.tap{
      go = false
      spinner.join
    }
  end

  # Compress a file with zlib
  def compress(file)
    if File.file?(file) # file file file file
      content = File.read(file)
      zipped = Zlib::Deflate.deflate(content)
      puts "Compressed '#{File.basename(file)}' : #{content.size - zipped.size} bytes smaller than original"
      return zipped
    else
      return false
    end
  end

  # Serve something, in this case a zipped file
  def serve(zipped)
    server = TCPServer.new(1174)
    puts "Server is up on port 1174\n\n"
    while true
      Signal.trap("INT") {
        puts "\nCaught interupt signal, server quit"
        exit
      }
      Thread.new(server.accept) do |client|
        print "Sending file to #{client.peeraddr[2]} "
        loading() {
          client.write zipped
        }
        puts "\nSuccessfully sent!\n\n"
        client.close
      end
    end
  end

  # Decompress and write to file
  def decompress(gz, outfile)
    unzipped = Zlib::Inflate.inflate(gz)
    out = File.open(outfile, 'w')
    out.write unzipped
    out.close
    return true
  end

  # Get a file from the server
  def get(ip)
    client = TCPSocket.new("#{ip}", 1174)
    Signal.trap("INT") {
      puts "\nCaught interupt signal, client quit"
      exit
    }
    return client.read
  end
end