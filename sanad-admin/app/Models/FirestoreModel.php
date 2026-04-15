<?php

namespace App\Models;

use App\Services\FirestoreService;
use Illuminate\Contracts\Auth\Authenticatable as AuthenticatableContract;
use Illuminate\Contracts\Support\Arrayable;
use JsonSerializable;
use Livewire\Wireable;

abstract class FirestoreModel implements Arrayable, AuthenticatableContract, JsonSerializable, Wireable
{
    protected array $attributes = [];

    protected array $original = [];

    public bool $exists = false;

    /**
     * The Firestore collection name.
     */
    abstract protected function getCollectionName(): string;

    /**
     * The primary key field name (usually 'id').
     */
    protected string $primaryKey = 'id';

    /**
     * Fillable fields (empty = all allowed).
     */
    protected array $fillable = [];

    /**
     * Fields that should be cast to specific types.
     */
    protected array $casts = [];

    public function __construct(array $attributes = [])
    {
        $this->fill($attributes);
    }

    /**
     * Create a new model instance from Firestore data.
     */
    public static function fromFirestore(array $data): static
    {
        $model = new static($data);
        $model->exists = true;
        $model->original = $model->attributes;

        return $model;
    }

    /**
     * Fill the model with attributes.
     */
    public function fill(array $attributes): static
    {
        foreach ($attributes as $key => $value) {
            $this->setAttribute($key, $value);
        }

        return $this;
    }

    /**
     * Get an attribute value.
     */
    public function getAttribute(string $key): mixed
    {
        if (array_key_exists($key, $this->attributes)) {
            return $this->castAttribute($key, $this->attributes[$key]);
        }

        return null;
    }

    /**
     * Get an attribute value (Eloquent compatibility for Filament).
     */
    public function getAttributeValue(string $key): mixed
    {
        return $this->getAttribute($key);
    }

    /**
     * Set an attribute value.
     */
    public function setAttribute(string $key, mixed $value): static
    {
        $this->attributes[$key] = $value;

        return $this;
    }

    /**
     * Cast an attribute to its specified type.
     */
    protected function castAttribute(string $key, mixed $value): mixed
    {
        if (! isset($this->casts[$key]) || $value === null) {
            return $value;
        }

        return match ($this->casts[$key]) {
            'bool', 'boolean' => (bool) $value,
            'int', 'integer' => (int) $value,
            'float', 'double' => (float) $value,
            'string' => (string) $value,
            'array' => is_array($value) ? $value : json_decode($value, true),
            'datetime' => $this->castToDateTime($value),
            default => $value,
        };
    }

    /**
     * Cast a value to a DateTime string.
     */
    protected function castToDateTime(mixed $value): ?string
    {
        if ($value === null) {
            return null;
        }

        if ($value instanceof \DateTimeInterface) {
            return $value->format('Y-m-d H:i:s');
        }

        if (is_array($value) && isset($value['_seconds'])) {
            return date('Y-m-d H:i:s', $value['_seconds']);
        }

        if (is_string($value)) {
            return $value;
        }

        if (is_numeric($value)) {
            return date('Y-m-d H:i:s', (int) $value);
        }

        return null;
    }

    /**
     * Get the model's primary key value.
     */
    public function getKey(): ?string
    {
        return $this->getAttribute($this->primaryKey);
    }

    /**
     * Get the primary key name.
     */
    public function getKeyName(): string
    {
        return $this->primaryKey;
    }

    /**
     * Get the Firestore collection/table name.
     */
    public function getTable(): string
    {
        return $this->getCollectionName();
    }

    /**
     * Convert the model to an array.
     */
    public function toArray(): array
    {
        $result = [];
        foreach ($this->attributes as $key => $value) {
            $result[$key] = $this->castAttribute($key, $value);
        }

        return $result;
    }

    /**
     * Convert the model to JSON-serializable format.
     */
    public function jsonSerialize(): array
    {
        return $this->toArray();
    }

    /**
     * Serialize for Livewire.
     */
    public function toLivewire(): array
    {
        return [
            'class' => static::class,
            'attributes' => $this->attributes,
            'exists' => $this->exists,
        ];
    }

    /**
     * Deserialize from Livewire.
     */
    public static function fromLivewire($value): static
    {
        $model = new static($value['attributes'] ?? []);
        $model->exists = $value['exists'] ?? false;
        $model->original = $model->attributes;

        return $model;
    }

    /**
     * Dynamic property getter.
     */
    public function __get(string $key): mixed
    {
        return $this->getAttribute($key);
    }

    /**
     * Dynamic property setter.
     */
    public function __set(string $key, mixed $value): void
    {
        $this->setAttribute($key, $value);
    }

    /**
     * Dynamic isset check.
     */
    public function __isset(string $key): bool
    {
        return array_key_exists($key, $this->attributes) && $this->attributes[$key] !== null;
    }

    /**
     * Get all attributes.
     */
    public function getAttributes(): array
    {
        return $this->attributes;
    }

    /**
     * Eloquent compatibility: check if a relation is loaded.
     */
    public function relationLoaded(string $key): bool
    {
        return false;
    }

    /**
     * Eloquent compatibility: get the model's class name for morph maps.
     */
    public function getMorphClass(): string
    {
        return static::class;
    }

    /**
     * Get the raw attributes without casting.
     */
    public function getRawAttributes(): array
    {
        return $this->attributes;
    }

    /**
     * Check if the model has been modified.
     */
    public function isDirty(): bool
    {
        return $this->attributes !== $this->original;
    }

    /**
     * Get changed attributes.
     */
    public function getDirty(): array
    {
        $dirty = [];
        foreach ($this->attributes as $key => $value) {
            if (! array_key_exists($key, $this->original) || $this->original[$key] !== $value) {
                $dirty[$key] = $value;
            }
        }

        return $dirty;
    }

    // ─── Authenticatable Contract ─────────────────────────────

    public function getAuthIdentifierName(): string
    {
        return $this->primaryKey;
    }

    public function getAuthIdentifier(): mixed
    {
        return $this->getKey();
    }

    public function getAuthPassword(): string
    {
        return ''; // Firebase handles passwords
    }

    public function getAuthPasswordName(): string
    {
        return 'password';
    }

    public function getRememberToken(): ?string
    {
        return $this->getAttribute('remember_token');
    }

    public function setRememberToken($value): void
    {
        $this->setAttribute('remember_token', $value);
    }

    public function getRememberTokenName(): string
    {
        return 'remember_token';
    }

    // ─── Firestore CRUD Operations ───────────────────────────

    /**
     * Find a model by its primary key.
     */
    public static function find(string $id): ?static
    {
        $model = new static;
        $service = app(FirestoreService::class);
        $data = $service->getDocument($model->getCollectionName(), $id);

        if ($data === null) {
            return null;
        }

        return static::fromFirestore($data);
    }

    /**
     * Get all documents from the collection.
     */
    public static function all(
        array $wheres = [],
        ?string $orderBy = null,
        string $direction = 'DESC',
        ?int $limit = null,
    ): array {
        $model = new static;
        $service = app(FirestoreService::class);
        $results = $service->queryCollection(
            $model->getCollectionName(),
            $wheres,
            $orderBy,
            $direction,
            $limit,
        );

        return array_map(fn (array $data) => static::fromFirestore($data), $results);
    }

    /**
     * Paginate the collection.
     */
    public static function paginate(
        int $perPage = 15,
        array $wheres = [],
        ?string $orderBy = null,
        string $direction = 'DESC',
        ?string $startAfterId = null,
    ): array {
        $model = new static;
        $service = app(FirestoreService::class);
        $result = $service->paginateCollection(
            $model->getCollectionName(),
            $perPage,
            $wheres,
            $orderBy,
            $direction,
            $startAfterId,
        );

        $result['data'] = array_map(
            fn (array $data) => static::fromFirestore($data),
            $result['data']
        );

        return $result;
    }

    /**
     * Save the model to Firestore.
     */
    public function save(): void
    {
        $service = app(FirestoreService::class);
        $data = $this->getDirty();

        if (empty($data) && $this->exists) {
            return;
        }

        $data = empty($data) ? $this->attributes : $data;
        // Remove 'id' from the data being saved (it's the document ID)
        unset($data['id']);

        if ($this->exists && $this->getKey()) {
            $service->updateDocument($this->getCollectionName(), $this->getKey(), $data);
        } else {
            $id = $this->getKey();
            if ($id) {
                $service->setDocument($this->getCollectionName(), $id, $data);
            } else {
                // Auto-generate ID
                $newId = $service->addDocument($this->getCollectionName(), $data);
                $this->setAttribute('id', $newId);
            }
            $this->exists = true;
        }

        $this->original = $this->attributes;
    }

    /**
     * Delete the model from Firestore.
     */
    public function delete(): void
    {
        if (! $this->exists || ! $this->getKey()) {
            return;
        }

        $service = app(FirestoreService::class);
        $service->deleteDocument($this->getCollectionName(), $this->getKey());
        $this->exists = false;
    }

    /**
     * Create a new model instance and save it.
     */
    public static function create(array $attributes): static
    {
        $model = new static($attributes);
        $model->save();

        return $model;
    }

    /**
     * Get the Filament-compatible record key.
     */
    public function getRouteKey(): string
    {
        return $this->getKey() ?? '';
    }

    public function getRouteKeyName(): string
    {
        return $this->primaryKey;
    }

    public function resolveRouteBinding($value, $field = null): ?static
    {
        if ($value instanceof static) {
            return $value;
        }

        if ($value instanceof self) {
            return static::fromFirestore($value->getAttributes());
        }

        return static::find((string) $value);
    }

    /**
     * Helper to return a safe display value with fallback.
     */
    public function safeGet(string $key, string $fallback = 'N/A'): string
    {
        $value = $this->getAttribute($key);

        return ($value !== null && $value !== '') ? (string) $value : $fallback;
    }
}
