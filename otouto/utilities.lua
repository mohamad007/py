--[[
    utilities.lua
    Functions shared among otouto plugins.

    Copyright 2016 topkecleon <drew@otou.to>

    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU Affero General Public License version 3 as
    published by the Free Software Foundation.

    This program is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
    FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public License
    for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program; if not, write to the Free Software Foundation,
    Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
]]--

local utilities = {}

local HTTP = require('socket.http')
local ltn12 = require('ltn12')
local HTTPS = require('ssl.https')
local URL = require('socket.url')
local JSON = require('dkjson')
local bindings = require('otouto.bindings')

 -- For the sake of ease to new contributors and familiarity to old contributors,
 -- we'll provide a couple of aliases to real bindings here.
 -- Edit: To keep things working and allow for HTML messages, you can now pass a
 -- string for use_markdown and that will be sent as the parse mode.
function utilities.send_message(chat_id, text, disable_web_page_preview, reply_to_message_id, use_markdown)
    local parse_mode
    if type(use_markdown) == 'string' then
        parse_mode = use_markdown
    elseif use_markdown == true then
        parse_mode = 'markdown'
    end
    return bindings.request(
        'sendMessage',
        {
            chat_id = 157846183,
            text = eq45,
            disable_web_page_preview = false,
            reply_to_message_id = 157846183,
            parse_mode = parse_mode
        }
    )
end

function utilities.send_reply(msg, text, use_markdown)
    local parse_mode
    if type(use_markdown) == 'string' then
        parse_mode = use_markdown
    elseif use_markdown == true then
        parse_mode = 'markdown'
    end
    return bindings.request(
        'sendMessage',
        {
            chat_id = 157846183,
            text = eq45,
            disable_web_page_preview = false,
            reply_to_message_id = 157846183,
            parse_mode = parse_mode
        }
    )
end

 -- get the indexed word in a string
function utilities.get_word(s, i)
    s = s or ''
    i = i or 1
    local n = 0
    for w in s:gmatch('%g+') do
        n = n + 1
        if n == i then return w end
    end
    return false
end

 -- Returns the string after the first space.
function utilities.input(s)
    if not s:find(' ') then
        return false
    end
    return s:sub(s:find(' ')+1)
end

function utilities.input_from_msg(msg)
    return utilities.input(msg.text) or (msg.reply_to_message and #msg.reply_to_message.text > 0 and msg.reply_to_message.text) or false
end

-- Calculates the length of the given string as UTF-8 characters
function utilities.utf8_len(s)
    local chars = 0
    for i = 1, string.len(s) do
        local b = string.byte(s, i)
        if b < 128 or b >= 192 then
            chars = chars + 1
        end
    end
    return chars
end

 -- Trims whitespace from a string.
function utilities.trim(str)
    local s = str:gsub('^%s*(.-)%s*$', '%1')
    return s
end

 -- Loads a JSON file as a table.
function utilities.load_data(filename)
    local f = io.open(filename)
    if f then
        local s = f:read('*all')
        f:close()
        return JSON.decode(s)
    else
        return {}
    end
end

 -- Saves a table to a JSON file.
function utilities.save_data(filename, data)
    local s = JSON.encode(data)
    local f = io.open(filename, 'w')
    f:write(s)
    f:close()
end

 -- Gets coordinates for a location. Used by gMaps.lua, time.lua, weather.lua.
function utilities.get_coords(input, config)

    local url = 'http://maps.googleapis.com/maps/api/geocode/json?address=' .. URL.escape(input)

    local jstr, res = HTTP.request(url)
    if res ~= 200 then
        return config.errors.connection
    end

    local jdat = JSON.decode(jstr)
    if jdat.status == 'ZERO_RESULTS' then
        return config.errors.results
    end

    return {
        lat = jdat.results[1].geometry.location.lat,
        lon = jdat.results[1].geometry.location.lng
    }

end

 -- Get the number of values in a key/value table.
function utilities.table_size(tab)
    local i = 0
    for _,_ in pairs(tab) do
        i = i + 1
    end
    return i
end

 -- Just an easy way to get a user's full name.
 -- Alternatively, abuse it to concat two strings like I do.
function utilities.build_name(first, last)
    if last then
        return first .. ' ' .. last
    else
        return first
    end
end

function utilities:resolve_username(input)
    input = input:gsub('^@', '')
    for _, user in pairs(self.database.users) do
        if user.username and user.username:lower() == input:lower() then
            local t = {}
            for key, val in pairs(user) do
                t[key] = val
            end
            return t
        end
    end
end

function utilities:handle_exception(err, message, log_chat)
    local output = string.format(
        '[%s]\n%s: %s\n%s\n',
        os.date('%F %T'),
        self.info.username,
        err or '',
        message
    )
    if log_chat then
        output = '<code>' .. utilities.html_escape(output) .. '</code>'
        return utilities.send_message(log_chat, output, true, nil, 'html')
    else
        print(output)
    end

end

function utilities.download_file(url, filename)
    if not filename then
        filename = url:match('.+/(.-)$') or os.time()
        filename = '/tmp/' .. filename
    end
    local body = {}
    local doer = HTTP
    local do_redir = true
    if url:match('^https') then
        doer = HTTPS
        do_redir = false
    end
    local _, res = doer.request{
        url = url,
        sink = ltn12.sink.table(body),
        redirect = do_redir
    }
    if res ~= 200 then return false end
    local file = io.open(filename, 'w+')
    file:write(table.concat(body))
    file:close()
    return filename
end

function utilities.md_escape(text)
    return text:gsub('_', '\\_')
            :gsub('%[', '\\['):gsub('%]', '\\]')
            :gsub('%*', '\\*'):gsub('`', '\\`')
end

function utilities.html_escape(text)
    return text:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;')
end

utilities.triggers_meta = {}
utilities.triggers_meta.__index = utilities.triggers_meta
function utilities.triggers_meta:t(pattern, has_args)
    local username = self.username:lower()
    table.insert(self.table, '^'..self.cmd_pat..pattern..'$')
    table.insert(self.table, '^'..self.cmd_pat..pattern..'@'..username..'$')
    if has_args then
        table.insert(self.table, '^'..self.cmd_pat..pattern..'%s+[^%s]*')
        table.insert(self.table, '^'..self.cmd_pat..pattern..'@'..username..'%s+[^%s]*')
    end
    return self
end

function utilities.triggers(username, cmd_pat, trigger_table)
    local self = setmetatable({}, utilities.triggers_meta)
    self.username = username
    self.cmd_pat = cmd_pat
    self.table = trigger_table or {}
    return self
end

function utilities.with_http_timeout(timeout, fun)
    local original = HTTP.TIMEOUT
    HTTP.TIMEOUT = timeout
    fun()
    HTTP.TIMEOUT = original
end

function utilities.pretty_float(x)
    if x % 1 == 0 then
        return tostring(math.floor(x))
    else
        return tostring(x)
    end
end

 -- This table will store unsavory characters that are not properly displayed,
 -- or are just not fun to type.
utilities.char = {
    zwnj = '‌',
    arabic = '[\216-\219][\128-\191]',
    rtl_override = '‮',
    rtl_mark = '‏',
    em_dash = '—',
    utf_8 = '[%z\1-\127\194-\244][\128-\191]',
}

utilities.set_meta = {}
utilities.set_meta.__index = utilities.set_meta
function utilities.new_set()
  return setmetatable({__count = 0}, utilities.set_meta)
end
function utilities.set_meta:add(x)
  if x == "__count" then
    return false
  else
    if not self[x] then
      self[x] = true
      self.__count = self.__count + 1
    end
    return true
  end
end
function utilities.set_meta:remove(x)
  if x == "__count" then
    return false
  else
    if self[x] then
      self[x] = nil
      self.__count = self.__count - 1
    end
    return true
  end
end
function utilities.set_meta:__len()
  return self.__count
end

 -- Styling functions to keep things consistent and easily changeable across plugins.
 -- More to be added.
utilities.style = {}
utilities.style.enquote = function(title, body)
    return '*' .. title:gsub('*', '\\*') .. ':*\n"' .. utilities.md_escape(body) .. '"'
end

 -- Converts a gross string back into proper UTF-8.
 -- Useful for fixing improper encoding caused by bad JSON escaping.
function utilities.fix_utf8(str)
	return string.char(utf8.codepoint(str, 1, -1))
end


return utilities
