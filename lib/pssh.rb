require 'haml'
require 'io/console'
require 'json'
require 'open-uri'
require 'optparse'
require 'pty'
require 'readline'
require 'tilt/haml'
require 'thin'
require 'rack/websocket'

require 'pssh/cli'
require 'pssh/client'
require 'pssh/console'
require 'pssh/pty'
require 'pssh/socket'
require 'pssh/version'
require 'pssh/web'

module Pssh

  DEFAULT_IO_MODE = 'rw'
  DEFAULT_SOCKET_PREFIX = 'pssh'
  DEFAULT_PORT = 8022
  DEFAULT_CACHE_LENGTH = 16384
  PSSH_DOMAIN = 'pssh.herokuapp.com'

  class << self

    attr_writer :io_mode
    attr_writer :socket_prefix
    attr_writer :command
    attr_writer :open_sessions
    attr_writer :port
    attr_writer :prompt
    attr_accessor :socket_path
    attr_accessor :cache_length
    attr_accessor :client
    attr_accessor :socket
    attr_accessor :pty
    attr_accessor :web

    def base_path
      File.dirname(__FILE__) + "/.."
    end

    def port
      @port ||= DEFAULT_PORT
    end

    def open_sessions
      @open_sessions ||= {}
    end

    # Public: This sets whether the connecting user can just view or can
    # also write to the screen. Values are 'rw, 'r', and 'w'.
    #
    # Returns a String.
    def io_mode
      @io_mode ||= DEFAULT_IO_MODE
    end

    # Public: This method retrieves the current IP address and compresses
    # it into a short url that can be shared to redirect to your site.
    def share_url
      return @share_url if @share_url
      ip = open("http://#{PSSH_DOMAIN}/ip").read
             .split('.')
             .map { |x| x.to_i.to_s(36).rjust(2,'0') }
             .join('')
      @share_url = "http://#{PSSH_DOMAIN}/#{ip}#{port.to_i.to_s(36)}"
    end

    # Public: This sets the amount of data that will be stored to show
    # new connections when they join.
    def cache_length
      @cache_length ||= DEFAULT_CACHE_LENGTH
    end

    # Public: This is the prefix that will be used to set up the socket for tmux or screen.
    #
    # Returns a String.
    def socket_prefix
      @socket_prefix ||= DEFAULT_SOCKET_PREFIX
    end

    # Public: This is the default socket path that will be used if one is not
    # provided in the command line arguments.
    #
    # Returns a String.
    def default_socket_path
      @socket_path ||= "#{socket_prefix}-#{SecureRandom.uuid}"
    end

    # Public: This is the tool which we are going to use for our multiplexing. If
    # we're currently in a tmux or screen session, that is the first option,
    # then it checks if tmux or screen is installed, and then it resorts to
    # a plain old shell.
    #
    # Returns a Symbol.
    def command
      @command ||=
        (ENV['TMUX'] && :tmux) ||
        (ENV['STY'] && :screen) ||
        :shell
    end

    # Public: This is the prompt character that shows up at the beginning of
    # Pssh's console.
    #
    # Returns a String.
    def prompt
      @prompt ||= "\u26a1 "
    end

    # Public: Generates a random id for a session and stores it to a list.
    #
    # Returns a String.
    def create_session(username=nil)
      id = SecureRandom.uuid
      open_sessions[id] = username
      id
    end

  end

end
