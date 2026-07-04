<?php

namespace App\Http\Controllers;

use App\Http\Requests\ProfileUpdateRequest;
use Illuminate\Http\Request;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Redirect;
use Illuminate\View\View;

class ProfileController extends Controller
{
    /**
     * Display the user's profile form.
     */
    public function edit(Request $request): View
    {
        return view('profile.edit', [
            'user' => $request->user(),
        ]);
    }

    /**
     * Update the user's profile information.
     *
     * メールアドレスはアカウントIDのため、ここでは変更不可(nameのみ更新)としている。
     */
    public function update(ProfileUpdateRequest $request): RedirectResponse
    {
        $request->user()->name = $request->validated()['name'];
        $request->user()->save();

        return Redirect::route('profile.edit')->with('status', 'profile-updated');
    }
}
