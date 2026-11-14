# Redis Stack — School ERP resources

Redis is the secondary document/vector store. MySQL remains the source of truth for the 11 relational School ERP entities.

## One-time setup (Windows PowerShell)

From the repository root:

    docker compose up -d
    .\scripts\setup-redis.ps1

The script creates or reuses .venv, installs the required Python packages, creates the JSON/RediSearch index if it does not exist, downloads the pretrained sentence-transformers/all-MiniLM-L6-v2 model on first use, and inserts three demonstration resources. The model generates real 384-dimensional embeddings; vectors are not random.

## Demonstrations

    # List resources
    .\.venv\Scripts\python.exe .\redis\manage_resources.py list

    # Semantic KNN search
    .\.venv\Scripts\python.exe .\redis\manage_resources.py search "How do teachers record attendance?"

    # Delete a demonstration resource
    .\.venv\Scripts\python.exe .\redis\manage_resources.py delete resource-exams

The utility demonstrates RedisJSON create/update (JSON.SET), read (list), and delete, plus RediSearch vector KNN retrieval. The sample documents are reference content, not live student or fee records. Actual school records remain in MySQL and should be accessed through authenticated Next.js API routes.
