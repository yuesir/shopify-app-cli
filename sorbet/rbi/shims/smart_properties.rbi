# typed: strict

 module SmartProperties
  module ClassMethods
    sig { params(name: Symbol, options: Hash).void }
    def property(name, options = {}); end

     sig { params(name: Symbol, options: Hash).void }
    def property!(name, options = {}); end
  end

   mixes_in_class_methods(ClassMethods)
end
