# Copies the Markdown docs into the build tree for Doxygen.
#
#   cmake -DSRC_DIR=<docs> -DDST_DIR=<out/docs> [-DCHANGELOG=<CHANGELOG.md>] -P PrepareDocsMarkdown.cmake
#
# Doxygen has no Mermaid support, so every ```mermaid fenced block is rewritten into an HTML-only
# <pre class="mermaid"> block, and pages that contain one get a <script> that loads mermaid.js
# (rendered in the browser). Everything else is copied unchanged. CHANGELOG.md is copied next to
# DST_DIR, with Doxygen-sensitive characters escaped, so the docs' ../CHANGELOG.md link resolves.

foreach(var SRC_DIR DST_DIR)
  if(NOT DEFINED ${var})
    message(FATAL_ERROR "PrepareDocsMarkdown.cmake: ${var} is not set")
  endif()
endforeach()

set(MERMAID_SCRIPT [=[
\htmlonly[block]
<script type="module">
import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11.4.1/dist/mermaid.esm.min.mjs";
mermaid.initialize({ startOnLoad: true, theme: "neutral" });
</script>
\endhtmlonly
]=])

file(REMOVE_RECURSE "${DST_DIR}")
file(GLOB_RECURSE markdown_files RELATIVE "${SRC_DIR}" "${SRC_DIR}/*.md")

foreach(rel IN LISTS markdown_files)
  file(READ "${SRC_DIR}/${rel}" content)

  string(FIND "${content}" "```mermaid" has_mermaid)
  if(NOT has_mermaid EQUAL -1)
    # ```mermaid\n ... \n``` -> \htmlonly[block]<pre class="mermaid"> ... </pre>\endhtmlonly
    string(REGEX REPLACE "```mermaid\n([^`]*)```"
      "\\\\htmlonly[block]\n<pre class=\"mermaid\">\n\\1</pre>\n\\\\endhtmlonly" content "${content}")
    string(APPEND content "\n${MERMAID_SCRIPT}")
  endif()

  file(WRITE "${DST_DIR}/${rel}" "${content}")
endforeach()

# CHANGELOG.md is plain GitHub Markdown: "@user" mentions and bare Windows paths would be read as
# Doxygen commands, so escape @ and \ outside `code spans` (code spans are verbatim in Doxygen).
if(DEFINED CHANGELOG AND EXISTS "${CHANGELOG}")
  file(READ "${CHANGELOG}" content)
  string(LENGTH "${content}" length)
  set(escaped "")
  set(in_code FALSE)
  set(i 0)
  while(i LESS length)
    string(SUBSTRING "${content}" ${i} 1 c)
    if(c STREQUAL "`")
      if(in_code)
        set(in_code FALSE)
      else()
        set(in_code TRUE)
      endif()
    elseif(NOT in_code AND (c STREQUAL "@" OR c STREQUAL "\\"))
      string(APPEND escaped "\\")
    endif()
    string(APPEND escaped "${c}")
    math(EXPR i "${i} + 1")
  endwhile()
  get_filename_component(parent "${DST_DIR}" DIRECTORY)
  file(WRITE "${parent}/CHANGELOG.md" "${escaped}")
endif()
