<?php

namespace App\View\Components;

use Illuminate\View\Component;
use Illuminate\View\View;

/**
 * パートナー画面用のレイアウト。<x-partner-app-layout> で使う。
 * 社内向けの AppLayout とはナビゲーションが異なる
 */
class PartnerAppLayout extends Component
{
    public function render(): View
    {
        return view('layouts.partner');
    }
}
