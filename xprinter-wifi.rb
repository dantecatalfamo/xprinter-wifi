#!/usr/bin/env ruby

require 'ipaddr'
require 'socket'

class Xprinter
  UNIT_SEPARATOR = "\x1f"
  ESCAPE = "\e"
  IP_COMMAND = "\x22"
  SN_COMMAND = "\xb0"
  GW_COMMAND = "\xb1"
  INTERFACE_COMMAND = "\xb2"
  WIFI_COMMAND = "\xb3"
  ALL_COMMAND = "\xb4"
  PREAMBLE = "#{UNIT_SEPARATOR}#{ESCAPE}#{UNIT_SEPARATOR}"
  NEWLINE = "\r\n"
  PORT = 9100
  
  def initialize(device)
    raise "Device does not exist" unless File.exists?(device)
    @printer = File.open(device, 'w')
  end

  def write(data)
    @printer.write(data)
    @printer.flush
  end

  def close
    @printer.close
  end

  def println(data)
    write(data + NEWLINE)
  end

  def set_network(...)
    cmd = set_network_command(...)
    write(cmd)
  end

  private
  
  def set_network_command(ip, mask, gateway, ssid, key, key_type = 6)
    ip_addr = IPAddr.new(ip)
    mask_addr = IPAddr.new(mask)
    gateway_addr = IPAddr.new(gateway)

    raise 'Not a valid IPv4 IP address' unless ip_addr.ipv4?
    raise 'Not a valud IPv4 subnet mask' unless mask_addr.ipv4?
    raise 'Not a valid IPv4 gateway' unless gateway_addr.ipv4?

    "#{PREAMBLE}#{ALL_COMMAND}#{ip_addr.hton.force_encoding('UTF-8')}" \
      "#{mask_addr.hton.force_encoding('UTF-8')}#{gateway_addr.hton.force_encoding('UTF-8')}" \
      "#{key_type.chr}#{ssid}\0#{key}\0"
  end

  class CLI
    ABOUT = <<~EOF
      usage: #{$PROGRAM_NAME} <device>

      Configure the wireless options for an Xprinter wireless thermal
      receipt printer. <device> is the device file of the printer. For
      example: /dev/usb/lp0.
    EOF
    def run
      device = ARGV[0]
      abort ABOUT unless device && File.exists?(device) && !File.stat(device).rdev.zero?
      @printer = Xprinter.new(device)
      puts "Connected to #{device}"

      print "IP> "
      ip = $stdin.gets.chomp
      print "Subnet Mask> "
      mask = $stdin.gets.chomp
      print "Gateway> "
      gateway = $stdin.gets.chomp
      print "SSID> "
      ssid = $stdin.gets.chomp
      print "Password> "
      key = $stdin.gets.chomp
      puts <<~KEY
          | Key Type           | Value |
          |--------------------+-------|
          | NULL               |    0  |
          | WEP64              |    1  |
          | WEP128             |    2  |
          | WPA_AES_PSK        |    3  |
          | WPA_TKIP_PSK       |    4  |
          | WPA_TKIP_AES_PSK   |    5  |
          | WPA2_AES_PSK       |    6  | (default)
          | WPA2_TKIP          |    7  |
          | WPA2_TKIP_AES_PSK  |    8  |
          | WPA_WPA2_MixedMode |    9  |
        KEY
      print "Key Type [6]> "
      key_type = Integer($stdin.gets.chomp, exception: false)
      key_type = key_type.nil? ? 6 : key_type
      key_type = key_type.chr

      @printer.set_network(ip, mask, gateway, ssid, key, key_type)
      puts "Sent!"
    end
  end
end


if $PROGRAM_NAME == __FILE__
  Xprinter::CLI.new.run
end
