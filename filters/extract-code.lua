--[[
Pandoc Lua filter to extract C and Solidity code blocks from presentation markdown.

This filter processes code blocks with language classes 'c' or 'solidity' and writes
them to output files for compilation. Code blocks can appear either as regular
markdown code blocks or within HTML comments.

Attributes:
  - include=false: Skip extraction of this code block
  - display-only: Skip extraction (for display purposes only)
  - signature-only: Skip extraction (shows function signature without implementation)

Output files:
  - fhe-programs/src/voting.c (all C code blocks)
  - contracts/BinaryVoting.sol (all Solidity code blocks with prepended header)
]]

-- Accumulated code blocks by language
local c_blocks = {}
local sol_blocks = {}

-- Statistics for informational purposes
local stats = {
   c_regular = 0,
   c_from_comments = 0,
   sol_regular = 0,
   sol_from_comments = 0,
   skipped = 0
}

--[[
Check if a code block should be included in extraction.

@param elem CodeBlock element to check
@return boolean true if should be included, false if should be skipped
]]
local function should_include_block(elem)
   -- Check for include=false attribute
   if elem.attributes and elem.attributes.include == "false" then
      return false
   end

   -- Check for skip classes
   local skip_classes = { "display-only", "signature-only" }
   for _, skip_class in ipairs(skip_classes) do
      for _, class in ipairs(elem.classes) do
         if class == skip_class then
            return false
         end
      end
   end

   return true
end

--[[
Process a code block and add it to the appropriate collection.

@param text string The code block content
@param language string The programming language ("c" or "solidity")
@param from_comment boolean Whether this came from an HTML comment
]]
local function process_code_block(text, language, from_comment)
   if language == "c" then
      table.insert(c_blocks, text)
      if from_comment then
         stats.c_from_comments = stats.c_from_comments + 1
      else
         stats.c_regular = stats.c_regular + 1
      end
   elseif language == "solidity" then
      table.insert(sol_blocks, text)
      if from_comment then
         stats.sol_from_comments = stats.sol_from_comments + 1
      else
         stats.sol_regular = stats.sol_regular + 1
      end
   end
end

--[[
Write accumulated code blocks to a file.

@param filepath string Path to the output file
@param blocks table Array of code block strings
@param prepend string Optional text to prepend to the file
@return boolean true if successful, false on error
]]
local function write_blocks_to_file(filepath, blocks, prepend)
   if #blocks == 0 then
      return true
   end

   -- Create directory (mkdir -p equivalent)
   local dir = filepath:match("^(.+)/[^/]+$")
   if dir then
      local mkdir_result = os.execute("mkdir -p " .. dir)
      if mkdir_result ~= 0 and mkdir_result ~= true then
         io.stderr:write("ERROR: Could not create directory " .. dir .. "\n")
         return false
      end
   end

   -- Open file for writing
   local file = io.open(filepath, "w")
   if not file then
      io.stderr:write("ERROR: Could not open " .. filepath .. " for writing\n")
      return false
   end

   -- Write prepend text if provided
   if prepend then
      file:write(prepend)
   end

   -- Write all blocks separated by blank lines
   for i, block in ipairs(blocks) do
      file:write(block)
      -- Add blank line between blocks (but not after last one)
      if i < #blocks then
         file:write("\n\n")
      end
   end

   file:close()
   return true
end

-- Filter function: Process regular code blocks
function CodeBlock(elem)
   -- Check if block should be included
   if not should_include_block(elem) then
      stats.skipped = stats.skipped + 1
      return elem
   end

   -- Process based on language class
   local language = elem.classes[1]
   if language == "c" or language == "solidity" then
      process_code_block(elem.text, language, false)
   end

   return elem
end

-- Filter function: Process HTML comments for code blocks
function RawBlock(elem)
   -- Only process HTML RawBlocks
   if elem.format ~= "html" then
      return elem
   end

   -- Check if this is an HTML comment
   local comment_content = elem.text:match("^<!%-%-%s*(.-)%s*%-%->$")
   if not comment_content then
      return elem
   end

   -- Extract all code blocks from the comment
   -- Pattern matches: ```language\n...code...\n```
   -- Using %s* to handle optional whitespace and [%s\r\n] for newlines
   for language, code in comment_content:gmatch("```([%w]+)[%s\r\n]+(.-)[%s\r\n]+```") do
      if language == "c" or language == "solidity" then
         process_code_block(code, language, true)
      end
   end

   return elem
end

-- Filter function: Write accumulated blocks to files after processing
function Meta(meta)
   -- Solidity prepend header
   local sol_prepend = [[// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

]]

   -- Write C code
   local c_success = write_blocks_to_file(
      "fhe-programs/src/voting.c",
      c_blocks,
      nil
   )

   -- Write Solidity code
   local sol_success = write_blocks_to_file(
      "contracts/BinaryVoting.sol",
      sol_blocks,
      sol_prepend
   )

   -- Report errors if any occurred
   if not c_success or not sol_success then
      io.stderr:write("ERROR: Failed to write one or more output files\n")
   end

   return meta
end
