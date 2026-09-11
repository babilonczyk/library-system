# Rails wraps a JSON body in a root key named after the controller's model, so
# {"title": "Solaris"} silently becomes {"book": {"title": "Solaris"}}.
#
# Turned off. The API documents one request shape, and a body missing its root
# key should be told so rather than quietly repaired into something that then
# fails validation for a different reason.
ActiveSupport.on_load(:action_controller) do
  wrap_parameters false
end
