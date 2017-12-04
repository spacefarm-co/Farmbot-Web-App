# Takes a corpus and an AST and tells you if it is syntactically valid.
# PROBABLY THE MOST COMPLICATED CODE IN ALL OF FARMBOT.
module CeleryScript
  class TypeCheckError < StandardError; end
  class Checker
    MISSING_ARG = "Expected node '%s' to have a '%s', but got: %s."
    EXTRA_ARGS  = "'%s' has unexpected arguments: %s. Allowed arguments: %s"
    BAD_LEAF    = "Expected leaf '%s' within '%s' to be one of: %s but got %s"
    MALFORMED   = "Expected '%s' to be a node or leaf, but it was neither"
    BAD_BODY    = "Body of '%s' node contains '%s' node. "\
                  "Expected one of: %s"
    UNBOUND_VAR = "Unbound variable: %s"

    attr_reader :tree, :corpus

    def initialize(tree, corpus)
      @tree, @corpus = tree, corpus
      self.freeze
    end

    def run!
      CeleryScript::TreeClimber.travel(tree, method(:validate).to_proc)
      tree
    end

    def run
      error || tree
    end

    def valid?
      error ? false : true
    end

    def error
      run!
      nil
    rescue TypeCheckError => e
      e
    end

    private

    def validate(node)
      p = node.try(:parent).try(:kind) || "root"
      validate_body(node)
      validate_node(node)
    end

    def validate_body(node)
      (node.body || []).each_with_index do |inner_node, i|
        allowed = corpus.bodies(node)
        body_ok = allowed.include?(inner_node.kind.to_sym)
        bad_body_kind(node, inner_node, i, allowed) unless body_ok
      end
    end

    def validate_node(node)
      check_arity(node)
      node.args.map { |array| check_arg_validity(*array) }
    end

    def check_arity(node)
        allowed = corpus.args(node)
        allowed.map do |arg|
          has_key = node.args.has_key?(arg) || node.args.has_key?(arg.to_s)
          unless has_key
            msgs = node.args.keys.join(", ")
            msgs = "nothing" if msgs.length < 1
          msg = MISSING_ARG % [node.kind, arg, msgs]
          raise TypeCheckError, msg
          end
        end
      has      = node.args.keys.map(&:to_sym) # Either bigger or equal.
      required = corpus.args(node) # Always smallest.
      if !(has.length === required.length)
        extras = has - required
        raise TypeCheckError, (EXTRA_ARGS % [node.kind, extras, allowed])
      end
    end

    def check_arg_validity(key, value)
      case value
      when AstNode
        validate_node_pairing(key, value)
      when AstLeaf
        validate_leaf_pairing(key, value)
        check_leaf(value)
      else
        malformed_node!(key)
      end
      run_additional_validations(value, key)
    end

    def validate_node_pairing(key, value)
      actual  = value.kind
      allowed = corpus.fetchArg(key).allowed_values.map(&:to_s)
      # It would be safe to run type checking here.
      if (actual == "identifier")
        allowed_types  = allowed.without("identifier")
        # Resolve the identifier.
        resolved_value = resolve_variable!(value)
        # Did it reolve?
        #   YES: Make sure it resolves to a `kind` from the list above.
      end
      ok      = allowed.include?(actual)
      raise TypeCheckError, (BAD_LEAF % [ value.kind,
                                          value.parent.kind,
                                          allowed.inspect,
                                          actual.inspect ]) unless ok
    end

    def validate_leaf_pairing(key, value)
      actual  = value.value.class
      allowed = corpus.fetchArg(key).allowed_values
      ok      = allowed.include?(actual)
      raise TypeCheckError, (BAD_LEAF % [ value.kind,
                                          value.parent.kind,
                                          allowed.inspect,
                                          actual.inspect]) unless ok
    end

    def bad_body_kind(prnt, child, i, ok)
      raise TypeCheckError, (BAD_BODY % [prnt.kind, child.kind, ok.inspect])
    end

    def check_leaf(node)
      allowed = corpus.values(node)
      actual = node.value.class
      unless allowed.include?(actual)
        raise TypeCheckError, (BAD_LEAF % [ node.kind,
                                            node.parent.kind,
                                            allowed.inspect,
                                            actual.inspect])
      end
    end

    def malformed_node!(expectation)
      raise TypeCheckError, (MALFORMED % expectation)
    end

    def run_additional_validations(node, expectation)
      corpus.validator(expectation).call(node, TypeCheckError, corpus)
    end

    # Calling this method with only one paramter
    # indicates a starting condition 🏁
    def resolve_variable!(node, origin = node)
      if (node === origin) && node.kind != "identifier"
        raise "You can only resolve `identifiers` nodes."
      end

      argss = node.args
      kind  = (argss["locals"] || argss[:locals])&.kind
      puts ("="*4)+(kind) if kind
      if (kind == "scope_declaration")
        binding.pry
      end

      case node.parent
      when AstNode
        # sequence: Check the `scope` arg
        # Keep recursing if we can't find a scope on this node.
        resolve_variable!(node.parent, origin)
      when nil # We've got an unbound variable.
        origin.invalidate!(UNBOUND_VAR % origin.args["label"].value)
      else
        raise "Invariant"
      end
    end

    def maybe_extract_scope
    end
  end
end
