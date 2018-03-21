# The `puppet_data` is a hiera 5 `data_hash` data provider function.
# See [the configuration guide documentation](https://docs.puppet.com/puppet/latest/hiera_config_yaml_5.html#configuring-a-hierarchy-level-built-in-backends) for
# how to use this function.
#
# @since 4.8.0
#

Puppet::Functions.create_function(:puppet_data) do
  dispatch :puppet_data do
    param 'Struct[{path=>String[1]}]', :options
    param 'Puppet::LookupContext', :context
  end

  argument_mismatch :missing_path do
    param 'Hash', :options
    param 'Puppet::LookupContext', :context
  end

  def puppet_data(options, context)
    path = options['path']
    context.cached_file_data(path) do |content|
      begin
        internal_evaluator = Puppet::Pops::Parser::EvaluatingParser.new
        ast                = internal_evaluator.parse_string(content)
        data               = evaluate_literal(ast)
        if data.is_a?(Hash)
          Puppet::Pops::Lookup::HieraConfig.symkeys_to_string(data)
        else
          msg = _("%{path}: file does not contain a valid puppet hash" % { path: path })
          if Puppet[:strict] == :error && data != false
            raise Puppet::DataBinding::LookupError, msg
          end
          Puppet.warning(msg)
          {}
        end
      rescue ArgumentError => ex
        msg = [
          %(An error occurred: '#{ex.message}'.  Only literals are acceptable.),
          'See https://github.com/puppetlabs/puppet/blob/master/lib/puppet/pops/evaluator/literal_evaluator.rb.'
        ].join(' ')
        raise Puppet::DataBinding::LookupError, msg
      rescue StandardError => ex
        raise Puppet::DataBinding::LookupError, "Unable to parse #{ex.message}"
      end
    end
  end

  def missing_path(_options, _context)
    [
      %(one of 'path', 'paths' 'glob', 'globs' or 'mapped_paths'),
      %(must be declared in hiera.yaml when using this data_hash function)
    ].join(' ')
  end

  def evaluate_literal(ast)
    catch :not_literal do
      return Puppet::Pops::Evaluator::LiteralEvaluator.new.literal(ast)
    end
    raise ArgumentError, _("The given 'ast' does not represent a literal value")
  end
end
