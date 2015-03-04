-- https://github.com/mirven/luaspec
local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")

spec = {
  contexts = {}, passed = 0, failed = 0, pending = 0, current = nil, trace = {}
}

Report = {}
Report.__index = Report

function Report:new(spec)
    local report = {        
        num_passed = spec.passed,
        num_failed = spec.failed,
        num_pending = spec.pending,
        total = spec.passed + spec.failed + spec.pending,
        results = {}
    }
    
    report.percent = report.num_passed/report.total*100
        
    local contexts = spec.contexts
    
    for index = 1, #contexts do
        report.results[index] = {
            name = contexts[index],         
            spec_results = contexts[contexts[index]]
        }
    end     
    
    return report       
end

function spec:report(verbose)
    local report = Report:new(self)
    local nCases = 0
    local nCasesPass = 0

    if report.num_failed == 0 and not verbose then
        print "all tests passed"
        return
    end
    
    for _, result in pairs(report.results) do
        print(("\n%s\n================================"):format(result.name))
        
        for description, r in pairs(result.spec_results) do
            local outcome = r.passed and 'pass' or "FAILED"
            
            nCasesPass = r.passed and nCasesPass + 1 or nCasesPass
            nCases = nCases + 1

            if verbose or not (verbose and r.passed) then
                print(("[ %s ] %-70s "):format(outcome, description))

                table.foreach(r.errors, function(index, error)
                    print("   ".. index..". Failed expectation : ".. error.message.."\n   "..error.trace)
                end)
            end
        end
    end

    local summary = [[
=========  Summary  ============
%s Cases, Passed : %s, Failed : %s
%s Expectations, Passed : %s, Failed : %s, Success rate : %.2f percent
Time Elapsed: %s seconds
]]

    print(summary:format(nCases, nCasesPass, nCases - nCasesPass, report.total, report.num_passed, report.num_failed, report.percent, os.time() - spec.start_time))
end

function spec:add_results(success, message, trace)
    if self.current.passed then
        self.current.passed = success
    end

    if success then
        self.passed = self.passed + 1
    else
        table.insert(self.current.errors, { message = message, trace = trace })
        self.failed = self.failed + 1
    end
end

function spec:add_context(name) 
    self.contexts[#self.contexts+1] = name
    self.contexts[name] = {}    
end

function spec:add_spec(context_name, spec_name)
    local context = self.contexts[context_name]
    context[spec_name] = { passed = true, errors = {} }
    self.current = context[spec_name]
end

function spec:add_pending_spec(context_name, spec_name, pending_description)
end

--

-- create tables to support pending specifications
local pending = {}

function pending.__newindex() error("You can't set properties on pending") end

function pending.__index(_, key) 
    if key == "description" then 
        return nil 
    else
        error("You can't get properties on pending") 
    end
end

function pending.__call(_, description)
    local o = { description = description}
    setmetatable(o, pending)
    return o
end 

setmetatable(pending, pending)

--

-- define matchers

matchers = {    
    should_be = function(value, expected)
        if value ~= expected then
            return false, "expecting "..tostring(expected)..", not ".. tostring(value)
        end
        return true
    end;

    should_not_be = function(value, expected)
        if value == expected then
            return false, "should not be "..tostring(value)
        end
        return true
    end;
    
    should_error = function(f)
        if pcall(f) then
            return false, "expecting an error but received none"
        end
        return true
    end;

    should_match = function(value, pattern) 
        if type(value) ~= 'string' then
            return false, "type error, should_match expecting target as string"
        end

        if not string.match(value, pattern) then
            return false, value .. "doesn't match pattern "..pattern
        end
        return true
    end;  
}
 
matchers.should_equal = matchers.should_be

--

-- expect returns an empty table with a 'method missing' metatable
-- which looks up the matcher.  The 'method missing' function
-- runs the matcher and records the result in the current spec
local function expect(target)
    return setmetatable({}, { 
        __index = function(_, matcher)
            return function(...)
                local success, message = matchers[matcher](target, ...)
            
                spec:add_results(success, message, debug.traceback())
            end
        end
    })
end


--

Context = {}
Context.__index = Context

function Context:new(context)
    for _, child in ipairs(context.children) do
        child.parent = context
    end
    return setmetatable(context, self)
end

function Context:run_befores(env)
    if self.parent then
        self.parent:run_befores(env)
    end
    if self.before then
        setfenv(self.before, env)
        self.before()
    end
end

function Context:run_afters(env)
    if self.after then
        setfenv(self.after, env)
        self.after()
    end
    if self.parent then
        self.parent:run_afters(env)
    end
end

function Context:run_spec(spec_name, spec_func, done)
    if getmetatable(spec_func) == pending then
    else
        spec:add_spec(self.name, spec_name)
        table.insert(spec.trace, spec_name)
        print("")
        print("======================== " .. os.date("%X") .. " R.U.N.N.I.N.G: " .. table.concat(spec.trace, " -> ") .. " ========================")
        print("")

        local mocks = {}

        -- setup the environment that the spec is run in, each spec is run in a new environment
        local env = {
            track_error = function(f)
                local status, err = pcall(f)
                return err
            end,
    
            expect = expect,
    
            mock = function(table, key, mock_value)         
                mocks[{ table = table, key = key }] = table[key]  -- store the old value
                table[key] = mock_value or Mock:new()
                return table[key]
            end
        }
        setmetatable(env, { __index = _G })

        -- run each spec with proper befores and afters
        self:run_befores(env)

        setfenv(spec_func, env)

        local success, message
        local done_after = function()
            scheduler.performWithDelayGlobal(function()
                self:run_afters(env)
            
                if not success then
                    spec:add_results(false, message, debug.traceback())
                end     
            
                -- restore stored values for mocks
                for key, old_value in pairs(mocks) do
                    key.table[key.key] = old_value
                end

                table.remove(spec.trace)
                done()
            end, 0)
        end

        success, message = pcall(spec_func, done_after)
        if not success then
            print(message)
        end
    end
end

function Context:run(complete)
    -- run all specs
    local n = 1
    local done
    local run_once = function(nr)
        local spec_name = self.specs[nr].spec_name
        local spec_func = self.specs[nr].spec_func
        self:run_spec(spec_name, spec_func, done)
    end

    done = function()
        n = n + 1
        if n <= #self.specs then
            run_once(n)
        else
            local cur_context = 0
            local child_complete
            child_complete = function()
                if cur_context > 0 then
                    table.remove(spec.trace)
                end

                cur_context = cur_context + 1
                if cur_context <= #self.children then
                    scheduler.performWithDelayGlobal(function()
                        table.insert(spec.trace, self.children[cur_context].name)
                        self.children[cur_context]:run(child_complete)
                    end, 1)
                else
                    complete()
                end
            end

            child_complete()
        end
    end

    if #self.specs > 0 then
        scheduler.performWithDelayGlobal(function()
            run_once(1)
        end, 0)
    else
        done()
    end
end

-- dsl for creating contexts

local function make_it_table()
    -- create and set metatables for 'it'
    local specs = {}
    local it = {}
    setmetatable(it, {
        -- this is called when it is assigned a function (e.g. it["spec name"] = function() ...)
        __newindex = function(_, spec_name, spec_func)
            specs[#specs+1] = {spec_name = spec_name, spec_func = spec_func}
        end
    })
    
    return it, specs
end

local make_describe_table

-- create an environment to run a context function in as well as the tables to collect 
-- the subcontexts and specs
local function create_context_env()
    local it, specs = make_it_table()
    local describe, sub_contexts = make_describe_table()

    -- create an environment to run the function in
    local context_env = {
        it = it,
        describe = describe,
        pending = pending
    }
    
    return context_env, sub_contexts, specs
end

-- Note: this is declared locally earlier so it is still local
function make_describe_table(auto_run)
    local describe = {}
    local contexts = {}
    local cur_context = 0
    local complete
    complete = function()
        cur_context = cur_context + 1
        table.remove(spec.trace)
        if cur_context <= #contexts then
            scheduler.performWithDelayGlobal(function()
                table.insert(spec.trace, contexts[cur_context].name)
                contexts[cur_context]:run(complete)
            end, 1)
        else
            spec:report(true)
        end
    end

    local describe_mt = {
        
        -- This function is called when a function is assigned to a describe table 
        -- (e.g. describe["context name"] = function() ...)
        __newindex = function(_, context_name, context_function)
        
            spec:add_context(context_name)

            local context_env, sub_contexts, specs = create_context_env()
            
            -- set the environment
            setfenv(context_function, context_env)
            
            -- run the context function which collects the data into context_env and sub_contexts
            context_function()          
            
            -- store the describe function in contexts
            contexts[#contexts+1] = Context:new { 
                name = context_name,
                before = context_env.before, 
                after = context_env.after, 
                specs = specs, 
                children = sub_contexts 
            }
            
            if auto_run then
                if #contexts == 1 then
                    spec.start_time = os.time()
                    complete()
                end
            end
        end
    }
    
    setmetatable(describe, describe_mt)
    
    return describe, contexts
end

describe = make_describe_table(true)

local capture_id = 0
--测试辅助函数
capture = function(filename)
    local fn = table.concat(spec.trace, " -> ")
    if filename ~= nil then
        fn = fn .. " -> " .. filename
    end

    capture_id = capture_id + 1

    fn = string.format("%03d", capture_id) .. "." .. fn

    QUtility:saveScreenshot("screenshots/" .. fn .. ".png")
end

fail = function(done, data) 
    expect("错误，终止当前测试！" .. JSON.encode(data)).should_be("")
    done()
end