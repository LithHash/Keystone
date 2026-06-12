--!strict
export type BindingManager = {
	_instance: InputBinding,
	_action: InputAction,

	getInstance: (self: BindingManager) -> InputBinding,
	getAction: (self: BindingManager) -> InputAction,

	setKeyCode: (self: BindingManager, keyCode: Enum.KeyCode) -> BindingManager,
	setUIButton: (self: BindingManager, button: GuiButton) -> BindingManager,

	destroy: (self: BindingManager) -> (),
}

export type ActionManager = {
	_instance: InputAction,
	_context: InputContext,

	setEnabled: (self: ActionManager, enabled: boolean) -> ActionManager,
	getEnabled: (self: ActionManager) -> boolean,

	getInstance: (self: ActionManager) -> InputAction,
	getContext: (self: ActionManager) -> InputContext,

	addBinding: (self: ActionManager, keyCode: Enum.KeyCode?) -> BindingManager,
	listBindings: (self: ActionManager) -> { BindingManager },

	onPressed: (self: ActionManager, callback: (...any) -> ()) -> RBXScriptConnection,
	onReleased: (self: ActionManager, callback: (...any) -> ()) -> RBXScriptConnection,
	onStateChanged: (self: ActionManager, callback: (...any) -> ()) -> RBXScriptConnection,
}

const inputsFolder = Instance.new("Folder")
do
	inputsFolder.Name = "Inputs"
	inputsFolder.Parent = script
end

const function _getContext(context: InputContext | string): InputContext?
	if not context then
		warn("Attempted to get context without valid arguments")
		return nil
	end

	if typeof(context) == "string" then
		return inputsFolder:FindFirstChild(context) :: InputContext?
	end

	return context :: InputContext
end

const function _createBindingManager(action: InputAction, binding: InputBinding): BindingManager
	return {
		_instance = binding,
		_action = action,

		getInstance = function(self: BindingManager)
			return self._instance
		end,

		getAction = function(self: BindingManager)
			return self._action
		end,

		setKeyCode = function(self: BindingManager, keyCode: Enum.KeyCode): BindingManager
			if typeof(keyCode) ~= "EnumItem" then
				warn("Attempted to set KeyCode to non-Enum value")
				return self
			end

			self._instance.KeyCode = keyCode

			return self
		end,

		setPrimaryModifier = function(self: BindingManager, modifier: Enum.KeyCode): BindingManager
			if typeof(modifier) ~= "EnumItem" then
				warn("Attempted to set PrimaryModifier to non-Enum value")
				return self
			end

			self._instance.PrimaryModifier = modifier

			return self
		end,

		setSecondaryModifier = function(self: BindingManager, modifier: Enum.KeyCode): BindingManager
			if typeof(modifier) ~= "EnumItem" then
				warn("Attempted to set SecondaryModifier to non-Enum value")
				return self
			end

			self._instance.SecondaryModifier = modifier

			return self
		end,

		setUIButton = function(self: BindingManager, button: GuiButton): BindingManager
			if not (typeof(button) == "Instance" and button:IsA("GuiButton")) then
				warn("Attempted to set UIButton to non-GuiButton value")
				return self
			end

			self._instance.UIButton = button

			return self
		end,

		destroy = function(self: BindingManager)
			self._instance:Destroy()
		end,
	}
end

const function _createActionManager(context: InputContext, action: InputAction): ActionManager
	return {
		_instance = action,
		_context = context,

		setEnabled = function(self: ActionManager, enabled: boolean): ActionManager
			if typeof(enabled) ~= "boolean" then
				warn("Attempted to set enabled to non-boolean value")
				return self
			end

			self._instance.Enabled = enabled

			return self
		end,

		getEnabled = function(self: ActionManager)
			return self._instance.Enabled
		end,

		getInstance = function(self: ActionManager)
			return self._instance
		end,

		getContext = function(self: ActionManager)
			return self._context
		end,

		addBinding = function(self: ActionManager, keyCode: Enum.KeyCode?): BindingManager
			const bindingInstance = Instance.new("InputBinding")
			if keyCode then
				bindingInstance.KeyCode = keyCode
			end
			bindingInstance.Parent = self._instance

			return _createBindingManager(self._instance, bindingInstance)
		end,

		listBindings = function(self: ActionManager): { BindingManager }
			const managers = {}
			for _, child in self._instance:GetChildren() do
				if child:IsA("InputBinding") then
					table.insert(managers, _createBindingManager(self._instance, child))
				end
			end

			return managers
		end,

		onPressed = function(self: ActionManager, callback: (...any) -> ()): RBXScriptConnection
			return self._instance.Pressed:Connect(callback)
		end,

		onReleased = function(self: ActionManager, callback: (...any) -> ()): RBXScriptConnection
			return self._instance.Released:Connect(callback)
		end,

		onStateChanged = function(self: ActionManager, callback: (...any) -> ()): RBXScriptConnection
			return self._instance.StateChanged:Connect(callback)
		end,
	}
end

const function createAction(
	contextReference: InputContext | string,
	name: string,
	inputType: Enum.InputActionType?
): ActionManager?
	const context = _getContext(contextReference)
	if not context then
		warn("Attempted to create action without valid context")
		return nil
	end

	const action = Instance.new("InputAction")
	action.Name = name
	action.Type = inputType or Enum.InputActionType.Bool
	action.Parent = context

	return _createActionManager(context, action)
end

const function createContext(contextName: string, priority: number, sink: boolean): InputContext?
	if not contextName or priority == nil or sink == nil then
		warn("Attempted to create context without valid arguments")
		return nil
	end

	local inputContext = Instance.new("InputContext")
	inputContext.Name = contextName
	inputContext.Priority = priority
	inputContext.Sink = sink
	inputContext.Parent = inputsFolder

	return inputContext
end

return table.freeze({
	createContext = createContext,
	createAction = createAction,
})
