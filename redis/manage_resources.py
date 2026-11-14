"""RedisJSON resources and pretrained semantic search for School ERP."""
from __future__ import annotations
import argparse
import json
import os
import sys
import numpy as np
import redis
from redis.commands.search.field import TagField, TextField, VectorField
from redis.commands.search.indexDefinition import IndexDefinition, IndexType
from redis.commands.search.query import Query
from sentence_transformers import SentenceTransformer

REDIS_URL = os.getenv("REDIS_URL", "redis://127.0.0.1:6379")
INDEX = "idx:school_resources"
PREFIX = "school:resource:"
MODEL_NAME = "sentence-transformers/all-MiniLM-L6-v2"
MODEL = None

def client():
    r = redis.Redis.from_url(REDIS_URL, decode_responses=False)
    r.ping()
    return r

def embedder():
    global MODEL
    if MODEL is None:
        print(f"Loading pretrained model: {MODEL_NAME}")
        MODEL = SentenceTransformer(MODEL_NAME)
    return MODEL

def ensure_index(r):
    try:
        r.ft(INDEX).info()
        print(f"Index already exists: {INDEX}")
    except Exception:
        schema = (
            TextField("$.title", as_name="title"),
            TagField("$.category", as_name="category"),
            TextField("$.body", as_name="body"),
            VectorField("$.embedding", "HNSW", {
                "TYPE": "FLOAT32", "DIM": 384, "DISTANCE_METRIC": "COSINE"
            }, as_name="embedding"),
        )
        r.ft(INDEX).create_index(
            schema,
            definition=IndexDefinition(prefix=[PREFIX], index_type=IndexType.JSON),
        )
        print(f"Created index: {INDEX}")

def save_resource(r, resource_id, title, category, body):
    vector = embedder().encode(f"{title}. {body}", normalize_embeddings=True)
    if vector.shape != (384,):
        raise ValueError(f"Expected 384 dimensions, received {vector.shape}")
    document = {
        "title": title, "category": category, "body": body,
        "embedding": vector.astype(np.float32).tolist(),
        "embedding_model": MODEL_NAME,
    }
    key = f"{PREFIX}{resource_id}"
    r.json().set(key, "$", document)
    print(f"Saved {key} with a genuine 384-dimensional embedding")

def seed(r):
    examples = [
        ("notice-attendance", "Attendance submission guidelines", "academic",
         "Teachers should record student attendance for each scheduled class. Attendance records support academic monitoring and reporting."),
        ("resource-exams", "Examination and results information", "academic",
         "Examination schedules, maximum marks and student results are maintained by the School ERP for authorized academic users."),
        ("resource-fees", "Fee payment information", "finance",
         "Fee payment records include the student, amount paid, payment date, payment method and transaction reference."),
    ]
    for item in examples:
        save_resource(r, *item)
    print(f"Loaded {len(examples)} demonstration resources.")

def list_resources(r):
    result = r.ft(INDEX).search(Query("*").paging(0, 100))
    for doc in result.docs:
        data = json.loads(doc.json)
        print(f"- {doc.id}: {data.get('title')} [{data.get('category')}]")
    print(f"Total resources: {result.total}")

def semantic_search(r, question, limit):
    vector = embedder().encode(question, normalize_embeddings=True).astype(np.float32).tobytes()
    query = (Query(f"*=>[KNN {limit} @embedding $vector AS score]")
             .sort_by("score").return_fields("title", "category", "body", "score").dialect(2))
    results = r.ft(INDEX).search(query, query_params={"vector": vector})
    print(f"Semantic results for: {question}")
    for item in results.docs:
        print(f"\n{item.title} [{item.category}] distance={float(item.score):.4f}")
        print(item.body)

def main():
    parser = argparse.ArgumentParser(description="School ERP Redis resource utility")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("setup")
    sub.add_parser("list")
    search = sub.add_parser("search")
    search.add_argument("question", nargs="?", default="How is student attendance recorded?")
    search.add_argument("--limit", type=int, default=3)
    delete = sub.add_parser("delete")
    delete.add_argument("resource_id")
    args = parser.parse_args()
    try:
        r = client()
        if args.command == "setup":
            ensure_index(r); seed(r); list_resources(r)
        elif args.command == "list":
            list_resources(r)
        elif args.command == "search":
            semantic_search(r, args.question, args.limit)
        elif args.command == "delete":
            key = f"{PREFIX}{args.resource_id}"
            print("Deleted." if r.delete(key) else "Resource not found.")
    except Exception as exc:
        print(f"Redis operation failed: {exc}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
