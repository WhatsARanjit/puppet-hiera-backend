# The `puppet_lookup_key` is a hiera 5 `lookup_key` data provider function.
# See [the configuration guide documentation](https://docs.puppet.com/puppet/latest/hiera_config_yaml_5.html#configuring-a-hierarchy-level-hiera-eyaml) for
# how to use this function.
#
# @since 5.0.0
#
require 'puppet_pal'
Puppet::Functions.create_function(:puppet_lookup_key) do
  dispatch :puppet_lookup_key do
    param 'String[1]', :key
    param 'Hash[String[1],Any]', :options
    param 'Puppet::LookupContext', :context
  end

  def puppet_lookup_key(key, options, context)
    return context.cached_value(key) if context.cache_has_key(key)
    unless options.include?('path')
      raise ArgumentError,
        _("'puppet_lookup_key': one of 'path', 'paths' 'glob', 'globs' or 'mapped_paths' must be declared in hiera.yaml"\
        " when using this lookup_key function")
    end

    context.cache(key, puppet_dsl_value(key, options, context))
  end

  def puppet_dsl_value(key, options, context)
    path = options['path']
    context.cached_file_data(path) do |content|
      result = Puppet::Pal.in_tmp_environment('pal_env', modulepath: ['/tmp/testmodules']) do |pal|
        lookup_dsl = <<-"PP"
          #{content}
          if defined('$#{key}') {
            return $#{key}
          } else {
            return undef
          }
        PP
        pal.evaluate_script_string(lookup_dsl)
      end
    end
  end
end
