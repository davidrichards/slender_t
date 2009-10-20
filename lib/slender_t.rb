class SlenderT
  
  require 'rubygems'
  require 'open-uri'
  require 'fastercsv'
  
  class << self
    def load(source, opts={})
      SlenderT.new(source, opts)
    end
  end
  
  attr_reader :spo, :pos, :osp
  
  def initialize(contents=nil, opts={})
    @spo, @pos, @osp = {}, {}, {}
    self.load(contents, opts) if contents
  end
  
  # Expects CSV, a filename, or a URL with triples in it
  # If there is a header in the file, use load(contents, :header => true)
  # so that we can ignore the first line
  # If there are special converters needed for FasterCSV to work, include them
  # in the options as well.
  def load(contents, opts={})
    table = infer_csv_contents(contents, opts)
    return nil unless contents
    table.each do |row|
      self.add(*row)
    end
  end
  
  def save(filename)
    File.open(filename, 'wb') {|f| f.write self.to_csv}
  end
  
  def add(subject, predicate, object)
    add_to_index(self.spo, subject, predicate, object)
    add_to_index(self.pos, predicate, object, subject)
    add_to_index(self.osp, object, subject, predicate)
    [subject, predicate, object]
  end
  
  def remove(subject, predicate, object)
    triples = find(subject, predicate, object)
    return true unless triples
    for s, p, o in triples do
      self.remove_from_index(self.spo, s, p, o)
      self.remove_from_index(self.pos, p, o, s)
      self.remove_from_index(self.osp, o, s, p)
    end
    [subject, predicate, object]
  end
  
  def find(subject=nil, predicate=nil, object=nil)
    begin
      if subject and predicate and object
        if self.spo[subject] and self.spo[subject][predicate] and self.spo[subject][predicate].include?(object)
          return [[subject, predicate, object]]
        else
          return []
        end
      elsif subject and predicate and object.nil?
        return self.spo[subject][predicate].map {|o| [subject, predicate, o]}
      elsif subject and predicate.nil? and object
        return self.osp[object][subject].map {|p| [subject, p, object]}
      elsif subject and predicate.nil? and object.nil?
        return self.spo[subject].inject([]) do |list, h|
          p, objects = h.first, h.last
          objects.each {|o| list << [subject, p, o]}
          list
        end
      elsif subject.nil? and predicate and object
        return self.pos[predicate][object].map {|s| [s, predicate, object]}
      elsif subject.nil? and predicate and object.nil?
        return self.pos[predicate].inject([]) do |list, h|
          o, subjects = h.first, h.last
          subjects.each {|s| list << [s, predicate, o]}
          list
        end
      elsif subject.nil? and predicate.nil? and object
        self.osp[object].inject([]) do |list, h|
          s, predicates = h.first, h.last
          predicates.each {|p| list << [s, p, object]}
          list
        end
      elsif subject.nil? and predicate.nil? and object.nil?
        list = []
        self.spo.each do |s, predicates|
          predicates.each do |p, objects|
            objects.each {|o| list << [s, p, o]}
          end
        end
        list
      end
    rescue
      []
    end
  end

  def inspect
    self.spo.keys.size > 20 ? "#{self.class}: #{self.spo.keys.size} unique subjects" : "#{self.class}: #{self.spo.keys.inspect}"
  end
  
  # Just very basic for now
  def to_csv
    self.find.map {|row| row.join(',')}.join("\n")
  end
  
  def value(subject=nil, predicate=nil, object=nil)
    s, p, o = find(subject, predicate, object).first
    return s unless subject
    return p unless predicate
    return o unless object
    nil
  end
  
  protected
    def add_to_index(index, a, b, c)
      if index.keys.include?(a) and index[a].keys.include?(b)
        # TODO: May not be efficient enough
        index[a][b] = index[a][b] | [c]
      elsif index.keys.include?(a)
        index[a][b] = [c]
      else
        index[a] = {}
        index[a][b] = [c]
      end
    end
    
    def remove_from_index(index, a, b, c)
      bs = index[a]
      cset = bs[b] if bs
      cset.delete(c) if cset
      bs.delete(b) if cset and cset.empty?
      index.delete(a) if bs and bs.empty?
      true
    end
    
    def infer_csv_contents(obj, opts={})
      begin
        contents = File.read(obj) if File.exist?(obj)
        open(obj) {|f| contents = f.read} unless contents
      rescue
        nil
      end
      contents ||= obj if obj.is_a?(String)
      return nil unless contents
      table = FCSV.parse(contents, default_csv_opts.merge(opts))
      labels = opts.fetch(:headers, false) ? table.shift : []
      while table.last.empty?
        table.pop
      end
      table
    end
    
    def default_csv_opts; {:converters => :all}; end

end

Dir.glob("#{File.dirname(__FILE__)}/slender_t/*.rb").each { |file| require file }
