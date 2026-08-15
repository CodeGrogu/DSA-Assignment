# Postman Collections (v3 YAML Format)

Collections in Local Mode are stored as directories containing v3 YAML files:

```text
postman/collections/
└── <collection-name>/
    ├── definition.yaml                # Collection/folder metadata and config
    ├── <request-name>.request.yaml    # Individual endpoint request definition
    └── .resources/                    # Request scripts, pre-request hooks, and examples
```

When new endpoints are implemented or updated in Postman Local Mode, commit the resulting directory-based YAML structure directly here.
