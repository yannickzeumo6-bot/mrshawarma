<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class AdminProductController extends Controller
{
    /** Tous les produits, y compris indisponibles. */
    public function index(): JsonResponse
    {
        $rows = Product::orderBy('category')->orderBy('sort_order')->orderBy('name')->get();

        return response()->json(['products' => $rows->map(fn ($p) => $p->toApi())->all()]);
    }

    private function rules(): array
    {
        return [
            'name' => 'required|string|max:80',
            'description' => 'nullable|string|max:200',
            'category' => 'required|string|max:40',
            'basePrice' => 'required|integer|min:0|max:1000000',
            'flavors' => 'nullable|string|max:300',
            'image' => 'nullable|image|max:4096',
        ];
    }

    /** Les photos sont stockées en base (table media) : pas de disque à conserver chez l'hébergeur. */
    private function saveImage(UploadedFile $file): string
    {
        $id = (string) Str::uuid();
        DB::table('media')->insert([
            'id' => $id,
            'mime' => $file->getMimeType() ?: 'image/jpeg',
            'data' => base64_encode((string) file_get_contents($file->getRealPath())),
            'created_at' => (int) round(microtime(true) * 1000),
        ]);

        return 'media:' . $id;
    }

    private function deleteImage(?string $path): void
    {
        if (! $path) return;
        if (str_starts_with($path, 'media:')) {
            DB::table('media')->where('id', substr($path, 6))->delete();
        } else {
            Storage::disk('public')->delete($path);
        }
    }

    /** "Orange, Ananas; Mangue" -> ['Orange','Ananas','Mangue'] */
    private function parseFlavors(?string $raw): array
    {
        $parts = preg_split('/[,;\n]+/', (string) $raw) ?: [];
        $parts = array_values(array_unique(array_filter(array_map('trim', $parts), fn ($f) => $f !== '')));

        return array_slice($parts, 0, 20);
    }

    public function store(Request $request): JsonResponse
    {
        $d = $request->validate($this->rules());
        $flavors = $this->parseFlavors($d['flavors'] ?? null);

        $product = Product::create([
            'id' => 'p' . Str::lower(Str::random(8)),
            'category' => Str::lower(trim($d['category'])),
            'name' => trim($d['name']),
            'description' => $d['description'] ?? null,
            'base_price' => $d['basePrice'],
            'has_flavors' => count($flavors) > 0,
            'flavors_json' => $flavors,
            'available' => $request->boolean('available', true),
            'active' => true,
            'image_path' => $request->hasFile('image') ? $this->saveImage($request->file('image')) : null,
        ]);

        return response()->json(['product' => $product->toApi()], 201);
    }

    /** Mise à jour (POST multipart pour pouvoir envoyer une nouvelle photo). */
    public function update(Request $request, string $id): JsonResponse
    {
        $product = Product::findOrFail($id);
        $d = $request->validate($this->rules());
        $flavors = $this->parseFlavors($d['flavors'] ?? null);

        $path = $product->image_path;
        if ($request->hasFile('image')) {
            $this->deleteImage($path);
            $path = $this->saveImage($request->file('image'));
        } elseif ($request->boolean('removeImage')) {
            $this->deleteImage($path);
            $path = null;
        }

        $product->update([
            'category' => Str::lower(trim($d['category'])),
            'name' => trim($d['name']),
            'description' => $d['description'] ?? null,
            'base_price' => $d['basePrice'],
            'has_flavors' => count($flavors) > 0,
            'flavors_json' => $flavors,
            'available' => $request->has('available') ? $request->boolean('available') : $product->available,
            'image_path' => $path,
        ]);

        return response()->json(['product' => $product->toApi()]);
    }

    /** Marquer un produit disponible / épuisé. */
    public function availability(Request $request, string $id): JsonResponse
    {
        $product = Product::findOrFail($id);
        $product->update(['available' => $request->boolean('available')]);

        return response()->json(['product' => $product->toApi()]);
    }

    public function destroy(string $id): JsonResponse
    {
        $product = Product::findOrFail($id);
        $this->deleteImage($product->image_path);
        $product->delete(); // les anciennes commandes gardent leur copie du produit

        return response()->json(['deleted' => true]);
    }
}
