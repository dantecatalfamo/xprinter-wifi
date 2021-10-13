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
  
  def initialize(device)
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

  def set_ip(...)
    cmd = set_ip_command(...)
    write(cmd)
  end

  def set_subnet_mask(...)
    cmd = set_subnet_mask_command(...)
    write(cmd)
  end

  def set_gateway(...)
    cmd = set_gateway_command(...)
    write(cmd)
  end

  def set_interface(...)
    cmd = set_interface_command(...)
    write(cmd)
  end

  def set_wifi_network(...)
    cmd = set_wifi_network_command(...)
    write(cmd)
  end

  def set_all_network(...)
    cmd = set_all_network_command(...)
    write(cmd)
  end

  private
  
  def set_ip_command(ip)
    addr = IPAddr.new(ip)
    raise 'Not a valid IPv4 address' unless addr.ipv4?

    "#{PREAMBLE}#{IP_COMMAND}#{addr.hton}"
  end

  def set_subnet_mask_command(mask)
    addr = IPAddr.new(mask)
    raise 'Not a valid IPv4 subnet mask' unless addr.ipv4?

    "#{PREAMBLE}#{SN_COMMAND}#{addr.hton}"
  end

  def set_gateway_command(gateway)
    addr = IPAddr.new(gateway)
    raise 'Not a valid IPv4 address' unless addr.ipv4?

    "#{PREAMBLE}#{GW_COMMAND}#{addr.hton}"
  end

  def set_interface_command(ip, mask, gateway)
    ip_addr = IPAddr.new(ip)
    mask_addr = IPAddr.new(mask)
    gateway_addr = IPAddr.new(gateway)

    raise 'Not a valid IPv4 IP address' unless ip_addr.ipv4?
    raise 'Not a valud IPv4 subnet mask' unless mask_addr.ipv4?
    raise 'Not a valid IPv4 gateway' unless gateway_addr.ipv4?

    "#{PREAMBLE}#{INTERFACE_COMMAND}#{ip_addr.hton}#{mask_addr.hton}#{gateway_addr.hton}"
  end

  def set_wifi_network_command(ssid, key, key_type = 6)
    "#{PREAMBLE}#{WIFI_COMMAND}#{key_type.chr}#{ssid}\0#{key}\0"
  end

  def set_all_network_command(ip, mask, gateway, ssid, key, key_type = 6)
    ip_addr = IPAddr.new(ip)
    mask_addr = IPAddr.new(mask)
    gateway_addr = IPAddr.new(gateway)

    raise 'Not a valid IPv4 IP address' unless ip_addr.ipv4?
    raise 'Not a valud IPv4 subnet mask' unless mask_addr.ipv4?
    raise 'Not a valid IPv4 gateway' unless gateway_addr.ipv4?

    "#{PREAMBLE}#{ALL_COMMAND}#{ip_addr.hton}#{mask_addr.hton}#{gateway_addr.hton}" \
      "#{key_type.chr}#{ssid}\0#{key}\0"
  end
end
