--[[
    GravityUI :: Signal
    -------------------
    A lightweight signal/event system for intra-library communication.
    
    Usage:
        local sig = Signal.new()
        local conn = sig:Connect(function(value) print(value) end)
        sig:Fire(42)     -- prints 42
        conn:Disconnect()
        sig:Destroy()
]]

local Signal = {}
Signal.__index = Signal

export type Connection = {
    Connected: boolean,
    Disconnect: (self: Connection) -> (),
}

export type SignalType = {
    Fire: (self: SignalType, ...any) -> (),
    Connect: (self: SignalType, fn: (...any) -> ()) -> Connection,
    Once: (self: SignalType, fn: (...any) -> ()) -> Connection,
    DisconnectAll: (self: SignalType) -> (),
    Destroy: (self: SignalType) -> (),
}

--- Creates a new Signal.
function Signal.new(): SignalType
    local self = setmetatable({}, Signal)
    self._listeners = {} :: { [thread | ((...any) -> ())]: true }
    self._destroyed = false
    return self :: any
end

--- Connects a callback function to the signal. Returns a Connection object.
function Signal:Connect(fn: (...any) -> ()): Connection
    assert(not self._destroyed, "Cannot connect to a destroyed Signal")
    self._listeners[fn] = true

    local conn = {
        Connected = true,
        Disconnect = function(c)
            if c.Connected then
                c.Connected = false
                self._listeners[fn] = nil
            end
        end,
    }
    return conn
end

--- Connects a callback that automatically disconnects after firing once.
function Signal:Once(fn: (...any) -> ()): Connection
    local conn
    conn = self:Connect(function(...)
        conn:Disconnect()
        fn(...)
    end)
    return conn
end

--- Fires the signal, calling all connected listeners with the given arguments.
function Signal:Fire(...: any)
    if self._destroyed then return end
    -- Snapshot listeners to avoid mutation issues mid-fire
    local snapshot = {}
    for fn in self._listeners do
        table.insert(snapshot, fn)
    end
    for _, fn in ipairs(snapshot) do
        task.spawn(fn, ...)
    end
end

--- Disconnects all listeners.
function Signal:DisconnectAll()
    self._listeners = {}
end

--- Destroys the signal and prevents further connections.
function Signal:Destroy()
    self:DisconnectAll()
    self._destroyed = true
end

return Signal
