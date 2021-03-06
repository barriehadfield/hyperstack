require 'hyperstack/ext/component/string'
require 'hyperstack/ext/component/hash'
require 'active_support/core_ext/class/attribute'
require 'hyperstack/internal/component/callbacks'
require 'react/rendering_context'
require 'hyperstack/internal/component'
require 'hyperstack/internal/component/instance_methods'
require 'hyperstack/internal/component/class_methods'
require 'hyperstack/internal/component/props_wrapper'
module Hyperstack

  module Component

    def self.included(base)
      base.include(Hyperstack::State::Observer)
      base.include(Hyperstack::Internal::Component::InstanceMethods)
      base.include(Hyperstack::Internal::Component::Callbacks)
      base.include(Hyperstack::Internal::Component::Tags)
      base.include(Hyperstack::Internal::Component::ShouldComponentUpdate)
      base.class_eval do
        class_attribute :initial_state
        define_callback :before_mount
        define_callback :after_mount
        define_callback :before_receive_props
        define_callback :before_update
        define_callback :after_update
        define_callback :before_unmount
        define_callback(:after_error) { Hyperstack::Internal::Component::ReactWrapper.add_after_error_hook(base) }
      end
      base.extend(Hyperstack::Internal::Component::ClassMethods)
    end

    def self.force_update!
      components = Hyperstack::Internal::Component.mounted_components.to_a
      components.each do |comp|
        next unless Hyperstack::Internal::Component.mounted_components.include? comp
        comp.force_update!
      end
    end

    def self.deprecation_warning(message)
      Hyperstack.deprecation_warning(name, message)
    end

    def deprecation_warning(message)
      Hyperstack.deprecation_warning(self.class.name, message)
    end

    def initialize(native_element)
      @native = native_element
    end

    def emit(event_name, *args)
      if Event::BUILT_IN_EVENTS.include?(built_in_event_name = "on#{event_name.to_s.event_camelize}")
        params[built_in_event_name].call(*args)
      else
        params["on_#{event_name}"].call(*args)
      end
    end

    def component_will_mount
      IsomorphicHelpers.load_context(true) if IsomorphicHelpers.on_opal_client?
      observing(immediate_update: true) do
        Hyperstack::Internal::Component.mounted_components << self
        run_callback(:before_mount)
      end
    end

    def component_did_mount
      observing(update_objects: true) { run_callback(:after_mount) }
    end

    def component_will_receive_props(next_props)
      # need to rethink how this works in opal-react, or if its actually that useful within the react.rb environment
      # for now we are just using it to clear processed_params
      observing(immediate_update: true) { run_callback(:before_receive_props, next_props) }
      @_receiving_props = true
    end

    def component_will_update(next_props, next_state)
      observing { run_callback(:before_update, next_props, next_state) }
      params._reset_all_others_cache if @_receiving_props
      @_receiving_props = false
    end

    def component_did_update(prev_props, prev_state)
      observing(update_objects: true) { run_callback(:after_update, prev_props, prev_state) }
    end

    def component_will_unmount
      observing do
        run_callback(:before_unmount)
        remove
        Hyperstack::Internal::Component.mounted_components.delete self
      end
    end

    def component_did_catch(error, info)
      observing { run_callback(:after_error, error, info) }
    end

    attr_reader :waiting_on_resources

    def mutations(_objects)
      # if we have to we may have to require that all objects respond to a "name" method (see legacy method update_react_js_state below)
      set_state('***_state_updated_at-***' => `Date.now() + Math.random()`)
    end

    def update_react_js_state(object, name, value)
      if object
        name = "#{object.class}.#{name}" unless object == self
        # Date.now() has only millisecond precision, if several notifications of
        # observer happen within a millisecond, updates may get lost.
        # to mitigate this the Math.random() appends some random number
        # this way notifactions will happen as expected by the rest of hyperloop
        set_state(
          '***_state_updated_at-***' => `Date.now() + Math.random()`,
          name => value
        )
      else
        set_state name => value
      end
    end

    def render
      raise 'no render defined'
    end unless method_defined?(:render)

    def _render_wrapper
      observing(rendering: true) do
        element = Internal::RenderingContext.render(nil) { render || '' }
        @waiting_on_resources =
          element.waiting_on_resources if element.respond_to? :waiting_on_resources
        element
      end
    end
  end
end
