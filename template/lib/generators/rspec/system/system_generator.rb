require 'generators/rspec'

module Rspec
  module Generators
    # @private
    class SystemGenerator < Base
      source_root File.expand_path('templates', __dir__)
      class_option :system_specs, type: :boolean, default: true, desc: 'Generate system specs'

      def generate_feature_spec
        return unless options[:system_specs]

        template template_name, File.join('spec/system', class_path, filename)
      end

      def template_name
        'system_spec.rb.erb'
      end

      def filename
        "#{table_name}_spec.rb"
      end
    end
  end
end
