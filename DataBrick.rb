#
#          -=- The Story of DataBrick -=-
# Not all things in this world may be blessed with lovely
#    ascii art, json, yaml, and other funky formats.
# Sometimes you need to get your arms dirty with some raw
#  unadulterated binary! Binary needn't scar you for life
#   though - so here's my little ORM for bits of binary.
#
#                                        Much Love!
#                                         <3 Bluebie <3

class DataBrick
  class << self; # Metaclass Madness!
    # Defines a piece of the Brick specification
    def define_piece name, type, options = {}
      name = name.to_sym
      @parts      ||= Array.new
      @part_types ||= Array.new
      @part_opts  ||= Array.new
      
      # if there's some smarter thing, do that!
      return send("define_one_#{type}", name, options) if respond_to?("define_one_#{type}")
      # otherwise do the default thing
      
      # add to ordered lists to keep everything orderly
      @parts.push name
      @part_types.push type
      @part_opts.push options
      
      # make a getter method!
      define_method(name) do
        @source.seek @position + offset_for(name)
        send("read_#{type}", @source, options)
      end
      
      # and a setter would be great too!
      case type.to_sym # Numbers always take the same number of bytes, so we can update them smartly!
      when :integer, :pointer
        define_method("#{name}=") do |value|
          @source.seek @position + offset_for(name)
          @source.write self.class.send("blob_#{type}", value, {}, options)
        end
      else # do things the old fashioned way otherwise, slow and steady wins this uncorruptable race!
        define_method("#{name}=") do |value|
          @source.seek @position
          update({name => value}, @source);
        end
      end
      
      define_method("length_for_#{name}") { send("type_length_#{type}", options) }
    end
    
    # creates a blob of binary from some properties in a hash, like the ones #to_h gives you
    # If you give it an IO as it's second param, it'll return an instance of this instead of
    # the blob, and write the blob straight to your IO for you right where you left it. :)
    def create properties, write_to = ''
      original_position = write_to.pos if write_to.respond_to?(:pos)
      @parts.each_with_index do |part, i|
        write_to << send("blob_#{@part_types[i]}", properties[part], properties, @part_opts[i])
      end
      return write_to.respond_to?(:seek) ? self.new(write_to, original_position) : write_to
    end
  end
  
  attr_reader :source, :position
  def initialize(source, position = false)
    @source = source
    @position = position || source.pos
  end
  
  def update properties
    blob = self.class.create(to_h.merge(properties))
    raise 'Length of brick is longer! cannot safely update without overflowing! Aborting!' if length < blob.length
    @source.seek @position
    @source.write updated
  end
  
  # returns the byte length of this block serialized
  def length; parts.inject(0) { |sofar, part| sofar + send("length_for_#{part}") }; end
  
  # add all the lengths for the bits before the specified one, to figure out the byte offset
  def offset_for(part)
    parts[0 ... parts.index(part)].inject(0) do |sofar, piece|
      sofar + self.send("length_for_#{piece}")
    end
  end
  
  # returns a hash version of this DataBrick
  def to_h
    hash = Hash.new
    parts.each { |part| hash[part] = send(part) }
    return hash
  end
  
  # returns the string of this thingy
  def to_s
    @source.seek @position
    @source.read(length)
  end
  
  # returns a stringy representation of this DataBrick's unique content
  def inspect
    "<#{self.class.name}##{position}: #{parts.map {|p| val = self.send(p); ".#{p}: #{val.is_a?(DataBrick) ? val.micro_inspect : val.inspect}" }.join(', ')}>"
  end
  
  def micro_inspect; "<#{self.class.name}##{position}>"; end
  
  protected
  def parts; self.class.instance_variable_get(:@parts); end
  PointerDefaults = {:bits => 32, :nil_if => 0xFFFFFFFF}
  
  # defines a simple string - defaults 8 bit length, :bits => 16 or 32 for longer strings!
  def self.define_one_string(name, opts = {})
    define_piece "#{name}_length", :string_length, {:string_name => name}.merge(opts)
    define_piece name,             :raw_string,    {:length_from => "#{name}_length".to_sym}.merge(opts)
  end
  
  # Thing readers!
  IntPacker = {8 => 'C', 16 => 'n', 32 => 'N', 64 => 'Q'}
  def read_integer(io, options = {}); options = {:bits => 8}.merge(options)
    source.read(options[:bits] / 8).unpack(IntPacker[options[:bits]]).first
  end
  
  def read_raw_string(io, options = {}); io.read(send(options[:length_from])); end
  alias_method :read_string_length, :read_integer
  
  def read_pointer(io, options = {})
    options = PointerDefaults.merge(options)
    ref = read_integer(io, options)
    return nil if ref == options[:nil_if]
    (options[:type] || self.class).new(io, ref)
  end
  
  
  # Thing blobbers!
  def self.blob_integer(int, props, options = {})
    [int.to_i].pack(IntPacker[options[:bits] || 8])
  end
  
  def self.blob_raw_string(str, props, options = {})
    str.to_s
  end
  
  def self.blob_pointer(pointee, props, options = {})
    options = PointerDefaults.merge(options)
    val = (pointee.position if pointee.respond_to?(:position)) || pointee
    val = options[:nil_if] if val == nil && options[:nil_if]
    self.blob_integer(val, props, options)
  end
  
  def self.blob_string_length(length, props, options = {})
    self.blob_integer(props[options[:string_name]].to_s.length, props, options)
  end
  
  # lengths for offset calculation
  def type_length_integer(opts); (opts[:bits] || 8) / 8; end
  def type_length_pointer(opts); (opts[:bits] || 32) / 8; end
  def type_length_raw_string(opts); send(opts[:length_from]); end
  alias_method :type_length_string_length, :type_length_integer
  
end

#             -=- BrickFu Lessons! -=-
#### Here's how to remember your friend's cats names:
# class CatPeople < DataBrick
#   define_piece :next, :pointer
#   define_piece :friend, :string
#   define_piece :cat, :string
# end
# 
#### And here's how you'd use that to make a little database:
# people = ["Bluebie", "Radar",     "Judofyr's Sister"]
# pets   = ["Phoenix", "Mr. Purrr", "Sibelius"]
# database = File.open('cats.db', 'w+')
# 
# last = false; # make this variable stay out here so it lasts forever!
# people.each_with_index do |person, index|
#   cat = CatPeople.create({
#           :friend => person,
#           :cat => pets[index]
#         }, database)
#   # link it up in to a list!
#   last.next = cat if last
#   last = cat
# end
# 
#### So that program put all your cat people in to the file, now in
#### another program we can read it like this!
# catman = CatPeople.new(open('cats.db'))
# puts "#{catman.friend} has awesome cat #{catman.cat}."
# begin
#   puts "Also, #{catman.friend} has a cat: #{catman.cat}."
#   catman = catman.next
# end until catman == nil
#

#### TODO:
# @ Add float types
# @ Maybe something for signed numbers?
# @ An Array type?
# @ Booleans type! (length = bools / 8)
# 







