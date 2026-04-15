<?php

namespace App\Services;

use Google\Auth\Credentials\ServiceAccountCredentials;
use Illuminate\Support\Facades\Http;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class FirestoreService
{
    protected string $projectId;

    protected string $baseUrl;

    protected ?string $accessToken = null;

    protected ?float $tokenExpiry = null;

    public function __construct()
    {
        try {
            $this->projectId = config('firebase.project_id');
            $this->baseUrl = "https://firestore.googleapis.com/v1/projects/{$this->projectId}/databases/(default)/documents";

            $this->refreshToken();
        } catch (\Exception $e) {
            Log::error("Firestore connection failed: {$e->getMessage()}");
            throw new \RuntimeException(
                __('firestore_connection_failed'),
                0,
                $e
            );
        }
    }

    protected function refreshToken(): void
    {
        if ($this->accessToken && $this->tokenExpiry && time() < $this->tokenExpiry - 60) {
            return;
        }

        $credentials = new ServiceAccountCredentials(
            ['https://www.googleapis.com/auth/datastore'],
            config('firebase.credentials')
        );

        $token = $credentials->fetchAuthToken();
        $this->accessToken = $token['access_token'];
        $this->tokenExpiry = time() + ($token['expires_in'] ?? 3600);
    }

    protected function request(string $method, string $url, array $options = []): array
    {
        $this->refreshToken();

        $response = Http::withToken($this->accessToken)
            ->timeout(30)
            ->{$method}($url, $options);

        if (! $response->successful()) {
            throw new \RuntimeException("Firestore API error: {$response->status()} - {$response->body()}");
        }

        return $response->json() ?? [];
    }

    /**
     * Get a single document by path.
     */
    public function getDocument(string $collection, string $documentId): ?array
    {
        try {
            $this->refreshToken();

            $response = Http::withToken($this->accessToken)
                ->timeout(30)
                ->get("{$this->baseUrl}/{$collection}/{$documentId}");

            if ($response->status() === 404) {
                return null;
            }

            if (! $response->successful()) {
                throw new \RuntimeException("Firestore API error: {$response->status()}");
            }

            return $this->parseDocument($response->json());
        } catch (\RuntimeException $e) {
            throw $e;
        } catch (\Exception $e) {
            Log::error("Firestore getDocument failed: {$e->getMessage()}", [
                'collection' => $collection,
                'document' => $documentId,
            ]);
            throw $e;
        }
    }

    /**
     * Set (create or overwrite) a document.
     */
    public function setDocument(string $collection, string $documentId, array $data, bool $merge = true): void
    {
        try {
            if ($merge) {
                $fields = $this->encodeFields($data);
                $updateMask = implode('&', array_map(fn ($k) => "updateMask.fieldPaths={$k}", array_keys($data)));
                $url = "{$this->baseUrl}/{$collection}/{$documentId}?{$updateMask}";
                $this->request('patch', $url, $fields ? ['fields' => $fields] : []);
            } else {
                $this->request('patch', "{$this->baseUrl}/{$collection}/{$documentId}", [
                    'fields' => $this->encodeFields($data),
                ]);
            }
        } catch (\Exception $e) {
            Log::error("Firestore setDocument failed: {$e->getMessage()}", [
                'collection' => $collection,
                'document' => $documentId,
            ]);
            throw $e;
        }
    }

    /**
     * Update specific fields on a document.
     */
    public function updateDocument(string $collection, string $documentId, array $data): void
    {
        try {
            $this->refreshToken();

            $fields = $this->encodeFields($data);
            $updateMask = implode('&', array_map(fn ($k) => "updateMask.fieldPaths={$k}", array_keys($data)));

            $response = Http::withToken($this->accessToken)
                ->timeout(30)
                ->patch(
                    "{$this->baseUrl}/{$collection}/{$documentId}?{$updateMask}",
                    ['fields' => $fields]
                );

            if (! $response->successful()) {
                throw new \RuntimeException("Firestore API error: {$response->status()} - {$response->body()}");
            }
        } catch (\Exception $e) {
            Log::error("Firestore updateDocument failed: {$e->getMessage()}", [
                'collection' => $collection,
                'document' => $documentId,
            ]);
            throw $e;
        }
    }

    /**
     * Delete a document.
     */
    public function deleteDocument(string $collection, string $documentId): void
    {
        try {
            $this->request('delete', "{$this->baseUrl}/{$collection}/{$documentId}");
        } catch (\Exception $e) {
            Log::error("Firestore deleteDocument failed: {$e->getMessage()}", [
                'collection' => $collection,
                'document' => $documentId,
            ]);
            throw $e;
        }
    }

    /**
     * Add a document with an auto-generated ID.
     */
    public function addDocument(string $collection, array $data): string
    {
        try {
            $response = $this->request('post', "{$this->baseUrl}/{$collection}", [
                'fields' => $this->encodeFields($data),
            ]);

            $name = $response['name'] ?? '';
            $parts = explode('/', $name);

            return end($parts);
        } catch (\Exception $e) {
            Log::error("Firestore addDocument failed: {$e->getMessage()}", [
                'collection' => $collection,
            ]);
            throw $e;
        }
    }

    /**
     * Delete a subcollection document.
     */
    public function deleteSubcollectionDocument(
        string $parentCollection,
        string $parentId,
        string $subcollection,
        string $documentId,
    ): void {
        try {
            $this->request('delete', "{$this->baseUrl}/{$parentCollection}/{$parentId}/{$subcollection}/{$documentId}");
        } catch (\Exception $e) {
            Log::error("Firestore deleteSubcollectionDocument failed: {$e->getMessage()}", [
                'path' => "{$parentCollection}/{$parentId}/{$subcollection}/{$documentId}",
            ]);
            throw $e;
        }
    }

    /**
     * Query a collection with optional filters, ordering, and pagination.
     */
    public function queryCollection(
        string $collection,
        array $wheres = [],
        ?string $orderBy = null,
        string $direction = 'DESC',
        ?int $limit = null,
        $startAfter = null,
    ): array {
        try {
            $structuredQuery = [
                'from' => [['collectionId' => $collection]],
            ];

            if (! empty($wheres)) {
                $filters = [];
                foreach ($wheres as $where) {
                    $filters[] = [
                        'fieldFilter' => [
                            'field' => ['fieldPath' => $where[0]],
                            'op' => $this->mapOperator($where[1]),
                            'value' => $this->encodeValue($where[2]),
                        ],
                    ];
                }

                if (count($filters) === 1) {
                    $structuredQuery['where'] = $filters[0];
                } else {
                    $structuredQuery['where'] = [
                        'compositeFilter' => [
                            'op' => 'AND',
                            'filters' => $filters,
                        ],
                    ];
                }
            }

            if ($orderBy) {
                $structuredQuery['orderBy'] = [[
                    'field' => ['fieldPath' => $orderBy],
                    'direction' => strtoupper($direction) === 'ASC' ? 'ASCENDING' : 'DESCENDING',
                ]];
            }

            if ($limit) {
                $structuredQuery['limit'] = $limit;
            }

            try {
                $response = $this->request('post', "{$this->baseUrl}:runQuery", [
                    'structuredQuery' => $structuredQuery,
                ]);
            } catch (\RuntimeException $e) {
                // If index is missing, retry without orderBy
                if ($orderBy && str_contains($e->getMessage(), 'FAILED_PRECONDITION')) {
                    Log::warning("Firestore missing index, retrying without orderBy: {$e->getMessage()}");
                    unset($structuredQuery['orderBy']);
                    $response = $this->request('post', "{$this->baseUrl}:runQuery", [
                        'structuredQuery' => $structuredQuery,
                    ]);
                } else {
                    throw $e;
                }
            }

            $results = [];
            foreach ($response as $item) {
                if (isset($item['document'])) {
                    $results[] = $this->parseDocument($item['document']);
                }
            }

            return $results;
        } catch (\Exception $e) {
            Log::error("Firestore queryCollection failed: {$e->getMessage()}", [
                'collection' => $collection,
                'wheres' => $wheres,
            ]);
            throw $e;
        }
    }

    /**
     * Query a collection group (across all subcollections with the same name).
     */
    public function queryCollectionGroup(
        string $collectionId,
        array $wheres = [],
        ?string $orderBy = null,
        string $direction = 'DESC',
        ?int $limit = null,
    ): array {
        try {
            $structuredQuery = [
                'from' => [['collectionId' => $collectionId, 'allDescendants' => true]],
            ];

            if (! empty($wheres)) {
                $filters = [];
                foreach ($wheres as $where) {
                    $filters[] = [
                        'fieldFilter' => [
                            'field' => ['fieldPath' => $where[0]],
                            'op' => $this->mapOperator($where[1]),
                            'value' => $this->encodeValue($where[2]),
                        ],
                    ];
                }

                $structuredQuery['where'] = count($filters) === 1
                    ? $filters[0]
                    : ['compositeFilter' => ['op' => 'AND', 'filters' => $filters]];
            }

            if ($orderBy) {
                $structuredQuery['orderBy'] = [[
                    'field' => ['fieldPath' => $orderBy],
                    'direction' => strtoupper($direction) === 'ASC' ? 'ASCENDING' : 'DESCENDING',
                ]];
            }

            if ($limit) {
                $structuredQuery['limit'] = $limit;
            }

            $response = $this->request('post', "{$this->baseUrl}:runQuery", [
                'structuredQuery' => $structuredQuery,
            ]);

            $results = [];
            foreach ($response as $item) {
                if (isset($item['document'])) {
                    $doc = $this->parseDocument($item['document']);
                    $pathParts = explode('/', $item['document']['name']);
                    if (count($pathParts) >= 4) {
                        $doc['_parent_id'] = $pathParts[count($pathParts) - 3] ?? null;
                    }
                    $results[] = $doc;
                }
            }

            return $results;
        } catch (\Exception $e) {
            Log::error("Firestore queryCollectionGroup failed: {$e->getMessage()}", [
                'collectionId' => $collectionId,
            ]);
            throw $e;
        }
    }

    /**
     * Paginate a collection query using real Firestore startAfter cursor (M6.3).
     *
     * Instead of fetching all documents and filtering in memory, this method
     * builds a structured query with startAt/endAt cursors for true
     * server-side pagination.
     */
    public function paginateCollection(
        string $collection,
        int $perPage = 15,
        array $wheres = [],
        ?string $orderBy = null,
        string $direction = 'DESC',
        ?string $startAfterId = null,
    ): array {
        try {
            $structuredQuery = [
                'from' => [['collectionId' => $collection]],
            ];

            // Apply filters
            if (! empty($wheres)) {
                $filters = [];
                foreach ($wheres as $where) {
                    $filters[] = [
                        'fieldFilter' => [
                            'field' => ['fieldPath' => $where[0]],
                            'op' => $this->mapOperator($where[1]),
                            'value' => $this->encodeValue($where[2]),
                        ],
                    ];
                }

                $structuredQuery['where'] = count($filters) === 1
                    ? $filters[0]
                    : ['compositeFilter' => ['op' => 'AND', 'filters' => $filters]];
            }

            // Apply ordering (required for cursor pagination)
            $effectiveOrderBy = $orderBy ?? '__name__';
            $structuredQuery['orderBy'] = [[
                'field' => ['fieldPath' => $effectiveOrderBy],
                'direction' => strtoupper($direction) === 'ASC' ? 'ASCENDING' : 'DESCENDING',
            ]];

            // Fetch perPage + 1 to detect if there are more results
            $structuredQuery['limit'] = $perPage + 1;

            // Apply real Firestore startAfter cursor (M6.3)
            if ($startAfterId) {
                // Fetch the cursor document to get its field values
                $cursorDoc = $this->getDocument($collection, $startAfterId);

                if ($cursorDoc) {
                    $cursorValues = [];

                    if ($effectiveOrderBy === '__name__') {
                        $cursorValues[] = [
                            'referenceValue' => "projects/{$this->projectId}/databases/(default)/documents/{$collection}/{$startAfterId}",
                        ];
                    } else {
                        $fieldValue = $cursorDoc[$effectiveOrderBy] ?? null;
                        $cursorValues[] = $this->encodeValue($fieldValue);
                    }

                    $structuredQuery['startAt'] = [
                        'values' => $cursorValues,
                        'before' => false, // startAfter semantics
                    ];
                }
            }

            try {
                $response = $this->request('post', "{$this->baseUrl}:runQuery", [
                    'structuredQuery' => $structuredQuery,
                ]);
            } catch (\RuntimeException $e) {
                // If index is missing, retry without orderBy
                if (str_contains($e->getMessage(), 'FAILED_PRECONDITION')) {
                    Log::warning("Firestore paginateCollection missing index, retrying: {$e->getMessage()}");
                    unset($structuredQuery['orderBy']);
                    unset($structuredQuery['startAt']);
                    $response = $this->request('post', "{$this->baseUrl}:runQuery", [
                        'structuredQuery' => $structuredQuery,
                    ]);
                } else {
                    throw $e;
                }
            }

            $results = [];
            foreach ($response as $item) {
                if (isset($item['document'])) {
                    $results[] = $this->parseDocument($item['document']);
                }
            }

            $hasMore = count($results) > $perPage;
            if ($hasMore) {
                $results = array_slice($results, 0, $perPage);
            }

            $lastId = ! empty($results) ? end($results)['id'] : null;

            return [
                'data' => $results,
                'last_id' => $lastId,
                'has_more' => $hasMore,
            ];
        } catch (\Exception $e) {
            Log::error("Firestore paginateCollection failed: {$e->getMessage()}", [
                'collection' => $collection,
            ]);
            throw $e;
        }
    }

    /**
     * Get all documents from a subcollection.
     */
    public function getSubcollection(
        string $parentCollection,
        string $parentId,
        string $subcollection,
        array $wheres = [],
        ?string $orderBy = null,
        string $direction = 'DESC',
        ?int $limit = null,
    ): array {
        try {
            $path = "{$parentCollection}/{$parentId}/{$subcollection}";

            $structuredQuery = [
                'from' => [['collectionId' => $subcollection]],
            ];

            if (! empty($wheres)) {
                $filters = [];
                foreach ($wheres as $where) {
                    $filters[] = [
                        'fieldFilter' => [
                            'field' => ['fieldPath' => $where[0]],
                            'op' => $this->mapOperator($where[1]),
                            'value' => $this->encodeValue($where[2]),
                        ],
                    ];
                }

                $structuredQuery['where'] = count($filters) === 1
                    ? $filters[0]
                    : ['compositeFilter' => ['op' => 'AND', 'filters' => $filters]];
            }

            if ($orderBy) {
                $structuredQuery['orderBy'] = [[
                    'field' => ['fieldPath' => $orderBy],
                    'direction' => strtoupper($direction) === 'ASC' ? 'ASCENDING' : 'DESCENDING',
                ]];
            }

            if ($limit) {
                $structuredQuery['limit'] = $limit;
            }

            $parentPath = "projects/{$this->projectId}/databases/(default)/documents/{$parentCollection}/{$parentId}";
            $url = "https://firestore.googleapis.com/v1/{$parentPath}:runQuery";

            $response = $this->request('post', $url, [
                'structuredQuery' => $structuredQuery,
            ]);

            $results = [];
            foreach ($response as $item) {
                if (isset($item['document'])) {
                    $results[] = $this->parseDocument($item['document']);
                }
            }

            return $results;
        } catch (\Exception $e) {
            Log::error("Firestore getSubcollection failed: {$e->getMessage()}", [
                'path' => "{$parentCollection}/{$parentId}/{$subcollection}",
            ]);
            throw $e;
        }
    }

    /**
     * Add a document to a subcollection.
     */
    public function addToSubcollection(
        string $parentCollection,
        string $parentId,
        string $subcollection,
        array $data,
        ?string $documentId = null,
    ): string {
        try {
            $basePath = "{$this->baseUrl}/{$parentCollection}/{$parentId}/{$subcollection}";

            if ($documentId) {
                $this->request('patch', "{$basePath}/{$documentId}", [
                    'fields' => $this->encodeFields($data),
                ]);

                return $documentId;
            }

            $response = $this->request('post', $basePath, [
                'fields' => $this->encodeFields($data),
            ]);

            $name = $response['name'] ?? '';
            $parts = explode('/', $name);

            return end($parts);
        } catch (\Exception $e) {
            Log::error("Firestore addToSubcollection failed: {$e->getMessage()}", [
                'path' => "{$parentCollection}/{$parentId}/{$subcollection}",
            ]);
            throw $e;
        }
    }

    /**
     * Count documents in a collection using Firestore aggregation API (M6.2).
     *
     * Uses the :runAggregationQuery endpoint instead of fetching all documents
     * and counting in memory. Falls back to full fetch if aggregation fails.
     */
    public function countDocuments(string $collection, array $wheres = []): int
    {
        try {
            $structuredQuery = [
                'from' => [['collectionId' => $collection]],
            ];

            if (! empty($wheres)) {
                $filters = [];
                foreach ($wheres as $where) {
                    $filters[] = [
                        'fieldFilter' => [
                            'field' => ['fieldPath' => $where[0]],
                            'op' => $this->mapOperator($where[1]),
                            'value' => $this->encodeValue($where[2]),
                        ],
                    ];
                }

                $structuredQuery['where'] = count($filters) === 1
                    ? $filters[0]
                    : ['compositeFilter' => ['op' => 'AND', 'filters' => $filters]];
            }

            $this->refreshToken();

            $response = Http::withToken($this->accessToken)
                ->timeout(30)
                ->post("{$this->baseUrl}:runAggregationQuery", [
                    'structuredAggregationQuery' => [
                        'structuredQuery' => $structuredQuery,
                        'aggregations' => [
                            [
                                'alias' => 'count',
                                'count' => new \stdClass(),
                            ],
                        ],
                    ],
                ]);

            if ($response->successful()) {
                $data = $response->json();
                foreach ($data as $item) {
                    if (isset($item['result']['aggregateFields']['count']['integerValue'])) {
                        return (int) $item['result']['aggregateFields']['count']['integerValue'];
                    }
                }
            }

            // Fallback: if aggregation API fails, use traditional count
            Log::warning("Firestore countDocuments aggregation failed, falling back to full query for {$collection}");
            $results = $this->queryCollection($collection, $wheres);

            return count($results);
        } catch (\Exception $e) {
            Log::error("Firestore countDocuments failed: {$e->getMessage()}", [
                'collection' => $collection,
            ]);
            throw $e;
        }
    }

    /**
     * Batch write multiple documents.
     */
    public function batchWrite(array $operations): void
    {
        try {
            $writes = [];
            foreach ($operations as $op) {
                $docPath = "projects/{$this->projectId}/databases/(default)/documents/{$op['collection']}/{$op['document']}";

                match ($op['type']) {
                    'set', 'update' => $writes[] = [
                        'update' => [
                            'name' => $docPath,
                            'fields' => $this->encodeFields($op['data']),
                        ],
                    ],
                    'delete' => $writes[] = ['delete' => $docPath],
                };
            }

            $this->request('post', "https://firestore.googleapis.com/v1/projects/{$this->projectId}/databases/(default)/documents:batchWrite", [
                'writes' => $writes,
            ]);
        } catch (\Exception $e) {
            Log::error("Firestore batchWrite failed: {$e->getMessage()}");
            throw $e;
        }
    }

    /**
     * Run a transaction (simplified - executes callback with this service).
     */
    public function runTransaction(callable $callback): mixed
    {
        return $callback($this);
    }

    // ---- Helpers ----

    /**
     * Create a Firestore-native timestamp from a Carbon/DateTime instance.
     *
     * Always use this instead of now()->toDateTimeString() when writing
     * timestamp fields to Firestore. This ensures the value is stored as
     * a Firestore Timestamp type rather than a plain string, which keeps
     * queries, ordering, and cross-platform reads consistent.
     */
    public static function timestamp(?\DateTimeInterface $dateTime = null): \DateTimeInterface
    {
        return $dateTime ?? Carbon::now('UTC');
    }

    /**
     * Convenience: return "now" as a Firestore-compatible DateTime.
     */
    public static function now(): \DateTimeInterface
    {
        return Carbon::now('UTC');
    }


    protected function parseDocument(array $doc): array
    {
        $name = $doc['name'] ?? '';
        $parts = explode('/', $name);
        $id = end($parts);

        $data = ['id' => $id];

        foreach ($doc['fields'] ?? [] as $key => $value) {
            $data[$key] = $this->decodeValue($value);
        }

        return $data;
    }

    protected function decodeValue(array $value): mixed
    {
        if (isset($value['stringValue'])) {
            return $value['stringValue'];
        }
        if (isset($value['integerValue'])) {
            return (int) $value['integerValue'];
        }
        if (isset($value['doubleValue'])) {
            return (float) $value['doubleValue'];
        }
        if (isset($value['booleanValue'])) {
            return (bool) $value['booleanValue'];
        }
        if (isset($value['nullValue'])) {
            return null;
        }
        if (isset($value['timestampValue'])) {
            return $value['timestampValue'];
        }
        if (isset($value['arrayValue'])) {
            return array_map(fn ($v) => $this->decodeValue($v), $value['arrayValue']['values'] ?? []);
        }
        if (isset($value['mapValue'])) {
            $map = [];
            foreach ($value['mapValue']['fields'] ?? [] as $k => $v) {
                $map[$k] = $this->decodeValue($v);
            }

            return $map;
        }
        if (isset($value['geoPointValue'])) {
            return $value['geoPointValue'];
        }
        if (isset($value['referenceValue'])) {
            return $value['referenceValue'];
        }

        return null;
    }

    protected function encodeValue(mixed $value): array
    {
        if (is_null($value)) {
            return ['nullValue' => null];
        }
        if (is_bool($value)) {
            return ['booleanValue' => $value];
        }
        if (is_int($value)) {
            return ['integerValue' => (string) $value];
        }
        if (is_float($value)) {
            return ['doubleValue' => $value];
        }
        if (is_string($value)) {
            return ['stringValue' => $value];
        }
        if (is_array($value)) {
            if (array_is_list($value)) {
                return ['arrayValue' => ['values' => array_map(fn ($v) => $this->encodeValue($v), $value)]];
            }

            $fields = [];
            foreach ($value as $k => $v) {
                $fields[$k] = $this->encodeValue($v);
            }

            return ['mapValue' => ['fields' => $fields]];
        }
        if ($value instanceof \DateTimeInterface) {
            return ['timestampValue' => $value->format('Y-m-d\TH:i:s.u\Z')];
        }
        return ['stringValue' => (string) $value];
    }

    protected function encodeFields(array $data): array
    {
        $fields = [];
        foreach ($data as $key => $value) {
            $fields[$key] = $this->encodeValue($value);
        }

        return $fields;
    }

    protected function mapOperator(string $op): string
    {
        return match ($op) {
            '=' , '==' => 'EQUAL',
            '!=' => 'NOT_EQUAL',
            '<' => 'LESS_THAN',
            '<=' => 'LESS_THAN_OR_EQUAL',
            '>' => 'GREATER_THAN',
            '>=' => 'GREATER_THAN_OR_EQUAL',
            'in' => 'IN',
            'not-in' => 'NOT_IN',
            'array-contains' => 'ARRAY_CONTAINS',
            'array-contains-any' => 'ARRAY_CONTAINS_ANY',
            default => 'EQUAL',
        };
    }
}
