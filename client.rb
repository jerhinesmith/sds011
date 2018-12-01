require 'rubyserial'

class Client
  attr_reader :device

  COMMANDS = {
    reporting_mode: 2,
    query: 4,
    device_id: 5,
    mode: 6,
    working_period: 8,
    firmware_version: 7
  }

  REPORTING_MODE = {
    active: 0,
    query: 1
  }

  MODE = {
    sleep: 0,
    work: 1
  }

  def initialize(device = nil)
    @device = device
  end

  def reporting_mode
    get :reporting_mode
  end

  def reporting_mode=(new_reporting_mode = :query)
    set :reporting_mode, [0x1, REPORTING_MODE[new_reporting_mode]]
  end

  def query
    get :query
  end

  def device_id=(new_device_id = nil)
    # Set the device ID
  end

  def mode
    get :mode
  end

  def mode=(new_mode = :work)
    set :mode, [0x1, MODE[new_mode]]
  end

  def working_period
    get :working_period
  end

  def working_period=(working_period = 0)
    # Set the working period
  end

  def firmware_version
    get :firmware_version
  end

  private

  def connection
    @connection ||= Serial.new(device, 9600, 8, :none, 1)
  end

  def build_command(command, data = [])
    head = 0xAA
    command_id = 0xB4
    command_value = COMMANDS[command]
    data = data.fill(0, data.length...12)
    device_id = [0xFF, 0xFF]
    checksum = [command_value, *data, *device_id].inject(:+) % 256
    tail = 0xAB

    [head, command_id, command_value, *data, *device_id, checksum, tail].pack('C*')
  end

  def read_response
    byte = 0
    # Ensure we're at the beginning of a message (0xAA is head)
    while byte != 0xAA
      # Get the next byte
      byte = connection.read(1).unpack('C').first
    end

    data = connection.read(9).unpack('C*')

    [byte, *data]
  end

  def get(command_type)
    command = build_command(command_type)
    connection.write(command)

    read_response
  end

  def set(command_type, params = [])
    command = build_command(command_type, params)
    connection.write(command)

    read_response
  end
end

# client = Client.new('/dev/ttyUSB1')
