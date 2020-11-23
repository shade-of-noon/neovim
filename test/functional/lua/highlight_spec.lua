local helpers = require('test.functional.helpers')(after_each)
local Screen = require('test.functional.ui.screen')
local clear = helpers.clear
local command = helpers.command
local feed = helpers.feed

describe('highlight.on_yank()', function()
  describe('arguments', function()
    local screen
    local enable_hl_on_yank = function(args)
      higroup = args['higroup'] or 'IncSearch'
      timeout = args['timeout'] or 150
      on_macro = args['on_macro'] and 'true' or 'false'
      on_visual = args['on_visual'] and 'true' or 'false'
      command('augroup YankHLGroup')
      command('au TextYankPost * '
        ..'silent! lua vim.highlight.on_yank {higroup="'..higroup
        ..'", timeout='..timeout..', on_macro='..on_macro
        ..', on_visual='..on_visual..'}')
      command('augroup END')
    end

    before_each(function()
      clear()
      screen = Screen.new(20,1)
      screen:attach()
      screen:set_default_attr_ids( {
        [0] = {reverse=true},
        [1] = {italic=true}
      } )
      feed('iuna línea solamente<esc>')
    end)

    after_each(function()
      command('au! YankHLGroup')
    end)

    it('works with non-default higroup', function()
      command('hi ItGroup gui=italic cterm=italic')
      enable_hl_on_yank {higroup='ItGroup'}
      feed('yy')
      screen:expect{grid=[[
        {1:una línea solament^e} |
                            |
      ]], timeout=100}
    end)

    it('works with non-default timeout', function()
      enable_hl_on_yank {timeout=330}
      feed('yy')
      screen:expect{grid=[[
        {0:una línea solament^e} |
                            |
      ]], timeout=100}

      feed('yy')
      screen:expect{grid=[[
        una línea solament^e |
                            |
      ]], timeout=330}
    end)

    -- FIXME: Why doesn't this work?
    pending('ignores visual yanks when on_visual=false', function()
      enable_hl_on_yank {on_visual=false}

      -- sanity check
      feed('yy')
      screen:expect{grid=[[
        {0:una línea solament^e} |
                            |
      ]], timeout=100}

      feed('Vy')
      screen:expect{grid=[[
        ^una línea solamente |
                            |
      ]], timeout=100}
    end)

    it('ignores in-macro yanks when on_macro=false', function()
      enable_hl_on_yank {on_macro=false,timeout=150}

      -- sanity check
      feed('yy')
      screen:expect{grid=[[
        {0:una línea solament^e} |
                            |
      ]], timeout=100}

      feed('0qqyiwwq@q')
      screen:expect{grid=[[
        una línea ^solamente |
                            |
      ]], timeout=200}
    end)
  end)

  describe('when virtualedit=all', function()
    local screen
    before_each(function()
      clear()
      screen = Screen.new(25,5)
      screen:attach()
      screen:set_default_attr_ids( {
        [0] = {reverse=true},
        [1] = {bold=true, foreground=Screen.colors.Blue},
      } )
      command('set virtualedit=all')
      command(string.gsub([[
        au TextYankPost *
         silent! lua vim.highlight.on_yank {
           timeout=250
         }]], '\n', ' '))
      feed('ishórt<cr>hint: a loonger line<cr>galỉłeö<esc>')
    end)

    it('block region is highlighted correctly', function()
      feed('gg0ljy')
      screen:expect{grid=[[
        {0:^sh}órt                    |
        {0:hi}nt: a loonger line     |
        galỉłeö                  |
        {1:~                        }|
                                 |
      ]], timeout=100}

      feed('2l3j12ly')
      screen:expect{grid=[[
        sh{0:^órt}                    |
        hi{0:nt: a loonger} line     |
        ga{0:lỉłeö}                  |
        {1:~                        }|
        block of 3 lines yanked  |
      ]], timeout=100}

      feed('5l2j6ly')
      screen:expect{grid=[[
        shórt  ^                  |
        hint: a {0:loonger} line     |
        galỉłeö                  |
        {1:~                        }|
        block of 3 lines yanked  |
      ]], timeout=100}
    end)

    it('yy highlights whole lines', function()
      feed('yy')
      screen:expect{grid=[[
        shórt                    |
        hint: a loonger line     |
        {0:galỉłe^ö}                  |
        {1:~                        }|
                                 |
      ]], timeout=100}

      feed('5lyy')
      screen:expect{grid=[[
        shórt                    |
        hint: a loonger line     |
        {0:galỉłeö}    ^              |
        {1:~                        }|
                                 |
      ]], timeout=100}

      feed('gg20|3yy')
      screen:expect{grid=[[
        {0:shórt}              ^      |
        {0:hint: a loonger line}     |
        {0:galỉłeö}                  |
        {1:~                        }|
        3 lines yanked           |
      ]], timeout=100}
    end)
  end)
end)
