# RAG Implementation Plan for LLM Agent Context

## Goal

To implement an automatic and relevant context retrieval system for the LLM Agent using Retrieval-Augmented Generation (RAG). This will replace the manual context management approach and provide the LLM with more pertinent information from the codebase, improving its coding assistance capabilities within the constraints of the context window.

## Chosen Strategy

Based on our brainstorming, we will pursue the following RAG strategy:

### 1. Information to Index (The Knowledge Base)

-   **Primary Target:** Code Chunks (Functions/Methods).
    -   *Rationale:* Provides granular, logically coherent units of code that are often highly relevant to coding tasks. More focused than full files.
-   **Secondary Target:** Associated Docstrings/Comments.
    -   *Rationale:* Contains valuable explanatory information directly linked to code chunks.
-   **Implementation Note:** We will need a robust way to parse the code (likely using Tree-sitter) to extract these chunks and their associated documentation.

### 2. Indexing and Retrieval Method

-   **Target Method:** Hybrid Search (Semantic Embeddings + Keyword/Symbol Search).
    -   *Rationale:* Combines the strengths of semantic understanding (finding conceptually similar code) with the precision of keyword/symbol matching (finding specific definitions mentioned by the user). This offers the most robust retrieval for coding tasks.
-   **Initial Implementation:** Start with Semantic Search using Code Embeddings.
    -   *Rationale:* Tackle the semantic aspect first. Keyword/symbol search can potentially leverage existing Neovim tools (LSP, ripgrep, ctags) later.
    -   *Implementation Note:* Research and select a suitable code embedding model and vector indexing approach (considerations: performance, local vs. cloud, complexity).
-   **Re-ranking:** Implement a re-ranking mechanism (e.g., Reciprocal Rank Fusion) when combining results from semantic and keyword search in the full hybrid implementation.

### 3. Retrieval Trigger and Query Formulation

-   **Trigger:** Automatic, before each request to the LLM.
    -   *Rationale:* Provides context proactively, fitting the "agentic" workflow.
-   **Query Source:** Combination of User Input and Editor State.
    -   *User Input:* The latest message/prompt from the user in the chat interface.
    -   *Editor State:* Information about the current buffer, cursor position (e.g., function name under cursor), and any selected code.
    -   *Rationale:* Creates a comprehensive query reflecting the user's immediate task and focus within the codebase.
    -   *Implementation Note:* Develop logic to intelligently combine these sources into a single effective query for the retrieval system.

## Next Steps (When Resuming)

1.  **Research & Setup:**
    -   Select and set up a code parsing library (Tree-sitter likely).
    -   Select a code embedding model and vector index/database suitable for local use within a Neovim plugin.
2.  **Indexing:** Implement the code chunk extraction and embedding generation process. Create a mechanism to index the current project's codebase.
3.  **Retrieval:** Implement the semantic search retrieval logic based on combined user input and editor state.
4.  **Integration:** Modify the `api.lua` module to perform RAG retrieval before calling the LLM and inject the retrieved context into the prompt.
5.  **Refinement:** Iterate on parsing, embedding quality, retrieval relevance, and query formulation.
6.  **(Later)** Add keyword/symbol search and hybrid re-ranking. 