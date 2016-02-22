{CompositeDisposable} = reqite 'atom'

emptyLine = /^\s*$/
objectLiteralLine = /^\s*[\w'"]+\s*\:\s*/m
continuationLine = /[\{\(;,]\s*$/

insertingNewLine = (action) -> (editor) ->
  action editor
  editor.insertNewlineBelow()

endLineWith = (terminator) -> (editor) ->
  editor.getCursors().forEach (cursor) ->
    line = cursor.getCurrentBufferLine()
    editor.moveToEndOfLine()

    if !terminator
      # guess the best terminator
      terminator = if objectLiteralLine.test(line) then ',' else ';'

    editor.insertText(terminator) if !continuationLine.test(line) and !emptyLine.test(line)

commands =
  'turbo-javascript:end-line-semicolon': -> endLineWith(';', false)
  'turbo-javascript:end-line-comma': -> endLineWith(',', false)
  'turbo-javascript:end-line-dot': -> endLineWith('.', false)
  'turbo-javascript:end-line-colon': -> endLineWith(':', false)
  'turbo-javascript:end-new-line': -> endLineWith('', true)
  'turbo-javascript:wrap-block': -> wrapBlock()

module.exports =
  activate: ->
    @subsctiptions = new CompositeDisposable
    @subsctiptions.add atom.commands.add 'atom-text-editor', commands

  deactivate: ->
    @subsctiptions.despose()
    @subsctiptions = null

  wrapBlock: () ->
    editor = atom.workspace.getActiveTextEditor()
    rangesToWrap = editor.getSelectedBufferRanges().filter((r) -> !r.isEmpty())
    if rangesToWrap.length
      rangesToWrap.sort((a, b) ->
        return if a.start.row > b.start.row then -1 else 1
      ).forEach((range) ->
        text = editor.getTextInBufferRange(range)
        if (/^\s*\{\s*/.test(text) && /\s*\}\s*/.test(text))
          # unwrap each selection from its block
          editor.setTextInBufferRange(range, text.replace(/\{\s*/, '').replace(/\s*\}/, ''))
        else
          # wrap each selection in a block
          editor.setTextInBufferRange(range, '{\n' + text + '\n}')
      )
      editor.autoIndentSelectedRows()
    else
      # create an empty block at each cursor
      editor.insertText('{\n\n}')
      editor.selectUp(2)
      editor.autoIndentSelectedRows()
      editor.moveRight()
      editor.moveUp()
      editor.moveToEndOfLine()
