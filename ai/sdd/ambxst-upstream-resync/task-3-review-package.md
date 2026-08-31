# Review package — Task 3 (upstream merge)

## Merge commit
33de0589f7725154930ab0219c12c686d9b1fb59
  parents: c78f2a11 6937e5b7
  subject: merge: upstream main into all-features

Parent 1 (c78f2a11) = our branch before the merge.
Parent 2 (6937e5b7) = upstream origin/main.

## What to review

The diff below is 'git show --cc', the COMBINED diff. It shows only hunks that
differ from BOTH parents, i.e. exactly the human decisions made while resolving.
Upstream's own 110 commits are deliberately not shown: they are not under review.

## Files our six features own (must still be present and functional)
  modules/services/KeyboardLayoutService.qml                     present 235 lines
  modules/bar/KeyboardLayoutIndicator.qml                        present 174 lines
  modules/bar/AudioDeviceSwitcher.qml                            present 484 lines
  modules/services/I18n.qml                                      present 114 lines
  modules/bar/BarResourceMonitor.qml                             present 703 lines
  modules/services/SystemResources.qml                           present 194 lines
  modules/services/CalendarService.qml                           present 323 lines
  modules/widgets/dashboard/controls/CalendarPanel.qml           present 1279 lines
  modules/widgets/defaultview/CompactPlayer.qml                  present 687 lines
  modules/widgets/dashboard/widgets/FullPlayer.qml               present 682 lines

## Feature markers still present
  I18n.t call sites:        68 files
  translations/ files:      en.json es.json languages.json ru.json 
  en.json keys:             751
  ru.json keys:             751
  es.json keys:             751
  Audio.incrementVolume:    modules/bar/ControlsButton.qml modules/widgets/defaultview/CompactPlayer.qml modules/widgets/dashboard/widgets/FullPlayer.qml 

## Diffstat of the combined diff
 .github/workflows/release.yml                      |    40 +
 .gitignore                                         |     2 +
 AGENTS.md                                          |    24 +-
 Makefile                                           |    47 +
 PLAN.md                                            |    65 +
 README.md                                          |    56 +-
 assets/presets/Ambxst Default/system.json          |     4 +-
 backend/ambxst                                     |   Bin 0 -> 14638146 bytes
 backend/cmd/ambxst/brightness.go                   |   186 +
 backend/cmd/ambxst/cmds_colorpicker.go             |   126 +
 backend/cmd/ambxst/cmds_media.go                   |   240 +
 backend/cmd/ambxst/cmds_tools.go                   |    95 +
 backend/cmd/ambxst/cmds_wallpaper_preset.go        |   258 +
 backend/cmd/ambxst/commands.go                     |   376 +
 backend/cmd/ambxst/main.go                         |   395 +
 backend/cmd/ambxst/screen.go                       |    73 +
 backend/cmd/ambxst/thumbs_native.go                |    91 +
 backend/cmd/ambxst/thumbs_native_test.go           |    60 +
 backend/go.mod                                     |    22 +
 backend/go.sum                                     |    28 +
 backend/internal/colorpicker/color.go              |   310 +
 backend/internal/colorpicker/picker.go             |   808 +
 backend/internal/colorpicker/shm.go                |    59 +
 backend/internal/colorpicker/state.go              |  1286 +
 backend/internal/colorpicker/state_test.go         |   399 +
 backend/internal/log/log.go                        |    25 +
 .../keyboard_shortcuts_inhibit.go                  |   287 +
 .../internal/proto/wlr_layer_shell/layer_shell.go  |   795 +
 .../internal/proto/wlr_screencopy/screencopy.go    |   535 +
 .../proto/wp_color_management/color_management.go  |  3012 ++
 .../internal/proto/wp_color_management/query.go    |    62 +
 backend/internal/proto/wp_viewporter/viewporter.go |   402 +
 backend/internal/screenshot/capture.go             |   461 +
 backend/internal/screenshot/cicp.go                |   108 +
 backend/internal/screenshot/engine_test.go         |   146 +
 backend/internal/screenshot/png.go                 |   286 +
 backend/internal/screenshot/shm.go                 |    41 +
 backend/internal/screenshot/types.go               |    44 +
 backend/internal/wayland/client/helpers.go         |    29 +
 backend/internal/wayland/shm/buffer.go             |   448 +
 backend/internal/wayland/shm/fd_linux.go           |    10 +
 backend/pkg/axmon/axmon.go                         |    93 +
 backend/pkg/axmon/axmon_test.go                    |    80 +
 backend/pkg/capture/capture.go                     |   124 +
 backend/pkg/daemon/daemon.go                       |   346 +
 backend/pkg/ipc/client.go                          |    99 +
 backend/pkg/ipc/server.go                          |   225 +
 backend/pkg/ipc/subscribe.go                       |    95 +
 backend/pkg/paths/paths.go                         |   149 +
 backend/pkg/paths/paths_test.go                    |    40 +
 backend/pkg/paths/shell_source.go                  |    70 +
 backend/pkg/svc/caffeine/service.go                |   244 +
 backend/pkg/svc/caffeine/service_test.go           |   132 +
 backend/pkg/svc/clipboard/service.go               |   378 +
 backend/pkg/svc/clipboard/watch.go                 |   123 +
 backend/pkg/svc/compositor/actions.go              |   395 +
 backend/pkg/svc/compositor/actions_test.go         |   253 +
 backend/pkg/svc/compositor/input.go                |   118 +
 backend/pkg/svc/compositor/parity_test.go          |    95 +
 backend/pkg/svc/compositor/proc.go                 |   331 +
 backend/pkg/svc/compositor/service.go              |   214 +
 backend/pkg/svc/compositor/service_test.go         |    87 +
 backend/pkg/svc/compositor/snapshot_test.go        |    44 +
 backend/pkg/svc/compositor/toml.go                 |   353 +
 backend/pkg/svc/compositor/toml_test.go            |   331 +
 backend/pkg/svc/config/service.go                  |   311 +
 backend/pkg/svc/config/service_migrate_test.go     |   123 +
 backend/pkg/svc/gamemode/service.go                |   177 +
 backend/pkg/svc/gamemode/service_test.go           |    67 +
 backend/pkg/svc/helpers.go                         |    63 +
 backend/pkg/svc/keystore/service.go                |   231 +
 backend/pkg/svc/linkpreview/service.go             |   371 +
 backend/pkg/svc/network/service.go                 |   249 +
 backend/pkg/svc/nightlight/service.go              |   299 +
 backend/pkg/svc/nightlight/service_test.go         |   173 +
 backend/pkg/svc/notify/notify.go                   |   129 +
 backend/pkg/svc/notify/notify_e2e_test.go          |   163 +
 backend/pkg/svc/notify/notify_test.go              |    79 +
 backend/pkg/svc/ocr/barcode.go                     |    51 +
 backend/pkg/svc/ocr/barcode_test.go                |    77 +
 backend/pkg/svc/ocr/service.go                     |   101 +
 backend/pkg/svc/powerprofile/service.go            |   257 +
 backend/pkg/svc/powerprofile/service_test.go       |   132 +
 backend/pkg/svc/preset/service.go                  |   238 +
 backend/pkg/svc/preset/service_test.go             |   191 +
 backend/pkg/svc/recorder/service.go                |   288 +
 backend/pkg/svc/screenshot/service.go              |   208 +
 backend/pkg/svc/sleep/service.go                   |   127 +
 backend/pkg/svc/systemmonitor/linux.go             |    53 +
 backend/pkg/svc/systemmonitor/monitor.go           |   410 +
 backend/pkg/svc/systemmonitor/service.go           |    66 +
 backend/pkg/svc/ui.go                              |    39 +
 backend/pkg/svc/wallpaper/service.go               |    92 +
 backend/pkg/svc/weather/client.go                  |   218 +
 backend/pkg/svc/weather/service.go                 |    39 +
 .../vendor/github.com/AvengeMedia/dankgo/LICENSE   |    21 +
 .../github.com/AvengeMedia/dankgo/syncmap/LICENSE  |    28 +
 .../AvengeMedia/dankgo/syncmap/syncmap.go          |   537 +
 .../github.com/AvengeMedia/dankgo/wayland/AUTHORS  |     3 +
 .../github.com/AvengeMedia/dankgo/wayland/LICENSE  |    24 +
 .../AvengeMedia/dankgo/wayland/client/client.go    |  7622 ++++
 .../AvengeMedia/dankgo/wayland/client/common.go    |    55 +
 .../AvengeMedia/dankgo/wayland/client/context.go   |   151 +
 .../AvengeMedia/dankgo/wayland/client/display.go   |    37 +
 .../AvengeMedia/dankgo/wayland/client/doc.go       |     6 +
 .../AvengeMedia/dankgo/wayland/client/event.go     |   120 +
 .../AvengeMedia/dankgo/wayland/client/request.go   |    44 +
 .../AvengeMedia/dankgo/wayland/client/util.go      |    24 +
 .../AvengeMedia/dankgo/wayland/xdg_shell/doc.go    |     3 +
 .../dankgo/wayland/xdg_shell/xdg_shell.go          |  2624 ++
 backend/vendor/github.com/davecgh/go-spew/LICENSE  |    15 +
 .../github.com/davecgh/go-spew/spew/bypass.go      |   145 +
 .../github.com/davecgh/go-spew/spew/bypasssafe.go  |    38 +
 .../github.com/davecgh/go-spew/spew/common.go      |   341 +
 .../github.com/davecgh/go-spew/spew/config.go      |   306 +
 .../vendor/github.com/davecgh/go-spew/spew/doc.go  |   211 +
 .../vendor/github.com/davecgh/go-spew/spew/dump.go |   509 +
 .../github.com/davecgh/go-spew/spew/format.go      |   419 +
 .../vendor/github.com/davecgh/go-spew/spew/spew.go |   148 +
 .../vendor/github.com/godbus/dbus/v5/.cirrus.yml   |    11 +
 .../vendor/github.com/godbus/dbus/v5/.golangci.yml |    13 +
 .../github.com/godbus/dbus/v5/CONTRIBUTING.md      |    50 +
 backend/vendor/github.com/godbus/dbus/v5/LICENSE   |    25 +
 .../vendor/github.com/godbus/dbus/v5/MAINTAINERS   |     3 +
 backend/vendor/github.com/godbus/dbus/v5/README.md |    47 +
 .../vendor/github.com/godbus/dbus/v5/SECURITY.md   |    13 +
 backend/vendor/github.com/godbus/dbus/v5/auth.go   |   257 +
 .../github.com/godbus/dbus/v5/auth_anonymous.go    |    16 +
 .../godbus/dbus/v5/auth_default_other.go           |     7 +
 .../godbus/dbus/v5/auth_default_windows.go         |     5 +
 .../github.com/godbus/dbus/v5/auth_external.go     |    26 +
 .../github.com/godbus/dbus/v5/auth_sha1_windows.go |   109 +
 backend/vendor/github.com/godbus/dbus/v5/call.go   |    66 +
 backend/vendor/github.com/godbus/dbus/v5/conn.go   |  1009 +
 .../github.com/godbus/dbus/v5/conn_darwin.go       |    36 +
 .../vendor/github.com/godbus/dbus/v5/conn_other.go |    83 +
 .../vendor/github.com/godbus/dbus/v5/conn_unix.go  |    40 +
 .../github.com/godbus/dbus/v5/conn_windows.go      |    13 +
 backend/vendor/github.com/godbus/dbus/v5/dbus.go   |   427 +
 .../vendor/github.com/godbus/dbus/v5/decoder.go    |   376 +
 .../github.com/godbus/dbus/v5/default_handler.go   |   338 +
 backend/vendor/github.com/godbus/dbus/v5/doc.go    |    70 +
 .../vendor/github.com/godbus/dbus/v5/encoder.go    |   235 +
 backend/vendor/github.com/godbus/dbus/v5/escape.go |    84 +
 backend/vendor/github.com/godbus/dbus/v5/export.go |   484 +
 backend/vendor/github.com/godbus/dbus/v5/match.go  |    89 +
 .../vendor/github.com/godbus/dbus/v5/message.go    |   393 +
 backend/vendor/github.com/godbus/dbus/v5/object.go |   181 +
 .../vendor/github.com/godbus/dbus/v5/sequence.go   |    24 +
 .../godbus/dbus/v5/sequential_handler.go           |   125 +
 .../github.com/godbus/dbus/v5/server_interfaces.go |   107 +
 backend/vendor/github.com/godbus/dbus/v5/sig.go    |   298 +
 .../github.com/godbus/dbus/v5/transport_darwin.go  |     6 +
 .../github.com/godbus/dbus/v5/transport_generic.go |    52 +
 .../godbus/dbus/v5/transport_nonce_tcp.go          |    41 +
 .../github.com/godbus/dbus/v5/transport_tcp.go     |    41 +
 .../github.com/godbus/dbus/v5/transport_unix.go    |   291 +
 .../godbus/dbus/v5/transport_unixcred_dragonfly.go |    95 +
 .../godbus/dbus/v5/transport_unixcred_freebsd.go   |    94 +
 .../godbus/dbus/v5/transport_unixcred_linux.go     |    25 +
 .../godbus/dbus/v5/transport_unixcred_netbsd.go    |    14 +
 .../godbus/dbus/v5/transport_unixcred_openbsd.go   |    14 +
 .../github.com/godbus/dbus/v5/transport_zos.go     |     6 +
 .../vendor/github.com/godbus/dbus/v5/variant.go    |   169 +
 .../github.com/godbus/dbus/v5/variant_lexer.go     |   284 +
 .../github.com/godbus/dbus/v5/variant_parser.go    |   815 +
 .../vendor/github.com/klauspost/compress/LICENSE   |   304 +
 .../github.com/klauspost/compress/flate/deflate.go |   996 +
 .../klauspost/compress/flate/dict_decoder.go       |   199 +
 .../klauspost/compress/flate/fast_encoder.go       |   189 +
 .../klauspost/compress/flate/huffman_bit_writer.go |  1174 +
 .../klauspost/compress/flate/huffman_code.go       |   417 +
 .../klauspost/compress/flate/huffman_sortByFreq.go |   159 +
 .../compress/flate/huffman_sortByLiteral.go        |   201 +
 .../github.com/klauspost/compress/flate/inflate.go |   957 +
 .../klauspost/compress/flate/inflate_gen.go        |  1337 +
 .../github.com/klauspost/compress/flate/level1.go  |   215 +
 .../github.com/klauspost/compress/flate/level2.go  |   214 +
 .../github.com/klauspost/compress/flate/level3.go  |   241 +
 .../github.com/klauspost/compress/flate/level4.go  |   221 +
 .../github.com/klauspost/compress/flate/level5.go  |   705 +
 .../github.com/klauspost/compress/flate/level6.go  |   325 +
 .../klauspost/compress/flate/matchlen_generic.go   |    34 +
 .../klauspost/compress/flate/regmask_amd64.go      |    37 +
 .../klauspost/compress/flate/regmask_other.go      |    39 +
 .../klauspost/compress/flate/stateless.go          |   325 +
 .../github.com/klauspost/compress/flate/token.go   |   379 +
 .../klauspost/compress/internal/le/le.go           |     5 +
 .../compress/internal/le/unsafe_disabled.go        |    42 +
 .../compress/internal/le/unsafe_enabled.go         |    52 +
 .../github.com/makiuchi-d/gozxing/.gitignore       |    12 +
 .../vendor/github.com/makiuchi-d/gozxing/LICENSE   |   230 +
 .../vendor/github.com/makiuchi-d/gozxing/README.md |   113 +
 .../makiuchi-d/gozxing/aztec/aztec_reader.go       |   107 +
 .../makiuchi-d/gozxing/aztec/decoder/decoder.go    |   446 +
 .../aztec/detector/aztec_detector_result.go        |    36 +
 .../makiuchi-d/gozxing/aztec/detector/detector.go  |   603 +
 .../makiuchi-d/gozxing/barcode_format.go           |   107 +
 .../github.com/makiuchi-d/gozxing/binarizr.go      |    45 +
 .../github.com/makiuchi-d/gozxing/binary_bitmap.go |    88 +
 .../github.com/makiuchi-d/gozxing/bit_array.go     |   260 +
 .../github.com/makiuchi-d/gozxing/bit_matrix.go    |   392 +
 .../makiuchi-d/gozxing/checksum_exception.go       |    25 +
 .../makiuchi-d/gozxing/common/bit_source.go        |    74 +
 .../makiuchi-d/gozxing/common/character_set_eci.go |   108 +
 .../makiuchi-d/gozxing/common/decoder_result.go    |   104 +
 .../gozxing/common/default_grid_sampler.go         |    70 +
 .../common/detector/white_rectangle_detector.go    |   301 +
 .../makiuchi-d/gozxing/common/detector_result.go   |    22 +
 .../makiuchi-d/gozxing/common/grid_sampler.go      |    81 +
 .../gozxing/common/perspective_transform.go        |    95 +
 .../gozxing/common/reedsolomon/generic_gf.go       |   120 +
 .../gozxing/common/reedsolomon/generic_gf_poly.go  |   238 +
 .../common/reedsolomon/reedsolomon_decoder.go      |   205 +
 .../common/reedsolomon/reedsolomon_encoder.go      |    59 +
 .../common/reedsolomon/reedsolomon_exception.go    |    60 +
 .../makiuchi-d/gozxing/common/string_utils.go      |   208 +
 .../makiuchi-d/gozxing/common/util/math_utils.go   |    32 +
 .../gozxing/datamatrix/datamatrix_reader.go        |   157 +
 .../gozxing/datamatrix/datamatrix_writer.go        |   186 +
 .../datamatrix/decoder/bit_matrix_parser.go        |   434 +
 .../gozxing/datamatrix/decoder/data_block.go       |   109 +
 .../decoder/decoded_bit_stream_parser.go           |   561 +
 .../gozxing/datamatrix/decoder/decoder.go          |   114 +
 .../gozxing/datamatrix/decoder/version.go          |   233 +
 .../gozxing/datamatrix/detector/detector.go        |   390 +
 .../gozxing/datamatrix/encoder/ascii_encoder.go    |    72 +
 .../gozxing/datamatrix/encoder/base256_encoder.go  |    67 +
 .../gozxing/datamatrix/encoder/c40_encoder.go      |   180 +
 .../encoder/datamatrix_symbol_info_144.go          |    19 +
 .../datamatrix/encoder/default_placement.go        |   190 +
 .../gozxing/datamatrix/encoder/edifact_encoder.go  |   158 +
 .../gozxing/datamatrix/encoder/encoder.go          |     6 +
 .../gozxing/datamatrix/encoder/encoder_context.go  |   124 +
 .../gozxing/datamatrix/encoder/error_correction.go |   153 +
 .../datamatrix/encoder/high_level_encoder.go       |   390 +
 .../gozxing/datamatrix/encoder/symbol_info.go      |   218 +
 .../datamatrix/encoder/symbol_shape_hint.go        |    11 +
 .../gozxing/datamatrix/encoder/text_encoder.go     |    63 +
 .../gozxing/datamatrix/encoder/x12_encoder.go      |    83 +
 .../makiuchi-d/gozxing/decode_hint_type.go         |   109 +
 .../github.com/makiuchi-d/gozxing/dimension.go     |    39 +
 .../makiuchi-d/gozxing/encode_hint_type.go         |   135 +
 .../makiuchi-d/gozxing/format_exception.go         |    25 +
 .../gozxing/global_histogram_binarizer.go          |   191 +
 .../makiuchi-d/gozxing/go_image_bit_matrix.go      |    24 +
 .../gozxing/go_image_luminance_source.go           |    88 +
 .../makiuchi-d/gozxing/hybrid_binarizer.go         |   180 +
 .../gozxing/inverted_luminance_source.go           |    64 +
 .../makiuchi-d/gozxing/luminance_source.go         |   151 +
 .../makiuchi-d/gozxing/not_found_exception.go      |    25 +
 .../makiuchi-d/gozxing/oned/codabar_reader.go      |   324 +
 .../makiuchi-d/gozxing/oned/codabar_writer.go      |   131 +
 .../makiuchi-d/gozxing/oned/code128_reader.go      |   551 +
 .../makiuchi-d/gozxing/oned/code128_writer.go      |   334 +
 .../makiuchi-d/gozxing/oned/code39_reader.go       |   329 +
 .../makiuchi-d/gozxing/oned/code39_writer.go       |   129 +
 .../makiuchi-d/gozxing/oned/code93_reader.go       |   296 +
 .../makiuchi-d/gozxing/oned/code93_writer.go       |   155 +
 .../makiuchi-d/gozxing/oned/ean13_reader.go        |   132 +
 .../makiuchi-d/gozxing/oned/ean13_writer.go        |    87 +
 .../makiuchi-d/gozxing/oned/ean8_reader.go         |    70 +
 .../makiuchi-d/gozxing/oned/ean8_writer.go         |    83 +
 .../gozxing/oned/ean_manufacturer_org_support.go   |   138 +
 .../makiuchi-d/gozxing/oned/itf_reader.go          |   381 +
 .../makiuchi-d/gozxing/oned/itf_writer.go          |    79 +
 .../gozxing/oned/multi_format_upcean_reader.go     |   116 +
 .../gozxing/oned/one_dimensional_code_writer.go    |   143 +
 .../makiuchi-d/gozxing/oned/oned_reader.go         |   312 +
 .../makiuchi-d/gozxing/oned/upca_reader.go         |    60 +
 .../makiuchi-d/gozxing/oned/upca_writer.go         |    27 +
 .../makiuchi-d/gozxing/oned/upce_reader.go         |   152 +
 .../makiuchi-d/gozxing/oned/upce_writer.go         |    80 +
 .../gozxing/oned/upcean_extension2_support.go      |   107 +
 .../gozxing/oned/upcean_extension5_support.go      |   171 +
 .../gozxing/oned/upcean_extension_support.go       |    38 +
 .../makiuchi-d/gozxing/oned/upcean_reader.go       |   404 +
 .../makiuchi-d/gozxing/oned/upcean_writer.go       |     7 +
 .../gozxing/planar_yuv_luminance_source.go         |   142 +
 .../gozxing/qrcode/decoder/bit_matrix_parser.go    |   206 +
 .../gozxing/qrcode/decoder/data_block.go           |    98 +
 .../makiuchi-d/gozxing/qrcode/decoder/data_mask.go |    99 +
 .../qrcode/decoder/decoded_bit_stream_parser.go    |   395 +
 .../makiuchi-d/gozxing/qrcode/decoder/decoder.go   |   168 +
 .../qrcode/decoder/error_correction_level.go       |    61 +
 .../gozxing/qrcode/decoder/format_information.go   |   106 +
 .../makiuchi-d/gozxing/qrcode/decoder/mode.go      |   100 +
 .../qrcode/decoder/qrcode_decoder_meta_data.go     |    24 +
 .../makiuchi-d/gozxing/qrcode/decoder/version.go   |   387 +
 .../gozxing/qrcode/detector/alignment_pattern.go   |    34 +
 .../qrcode/detector/alignment_pattern_finder.go    |   203 +
 .../makiuchi-d/gozxing/qrcode/detector/detector.go |   340 +
 .../gozxing/qrcode/detector/finder_pattern.go      |    49 +
 .../qrcode/detector/finder_pattern_finder.go       |   544 +
 .../gozxing/qrcode/detector/finder_pattern_info.go |    26 +
 .../gozxing/qrcode/encoder/block_pair.go           |    18 +
 .../gozxing/qrcode/encoder/byte_matrix.go          |    69 +
 .../makiuchi-d/gozxing/qrcode/encoder/encoder.go   |   630 +
 .../makiuchi-d/gozxing/qrcode/encoder/mask_util.go |   206 +
 .../gozxing/qrcode/encoder/matrix_util.go          |   509 +
 .../makiuchi-d/gozxing/qrcode/encoder/qrcode.go    |    88 +
 .../makiuchi-d/gozxing/qrcode/qrcode_reader.go     |   199 +
 .../makiuchi-d/gozxing/qrcode/qrcode_writer.go     |   130 +
 .../vendor/github.com/makiuchi-d/gozxing/reader.go |    36 +
 .../makiuchi-d/gozxing/reader_exception.go         |    68 +
 .../vendor/github.com/makiuchi-d/gozxing/result.go |    97 +
 .../makiuchi-d/gozxing/result_metadata_type.go     |   112 +
 .../github.com/makiuchi-d/gozxing/result_point.go  |    72 +
 .../makiuchi-d/gozxing/result_point_callback.go    |     3 +
 .../makiuchi-d/gozxing/rgb_luminance_source.go     |   113 +
 .../vendor/github.com/makiuchi-d/gozxing/writer.go |    26 +
 .../makiuchi-d/gozxing/writer_exception.go         |    24 +
 .../vendor/github.com/pmezard/go-difflib/LICENSE   |    27 +
 .../pmezard/go-difflib/difflib/difflib.go          |   772 +
 backend/vendor/github.com/stretchr/testify/LICENSE |    21 +
 .../stretchr/testify/assert/assertion_compare.go   |   495 +
 .../stretchr/testify/assert/assertion_format.go    |   866 +
 .../testify/assert/assertion_format.go.tmpl        |     5 +
 .../stretchr/testify/assert/assertion_forward.go   |  1723 +
 .../testify/assert/assertion_forward.go.tmpl       |     5 +
 .../stretchr/testify/assert/assertion_order.go     |    81 +
 .../stretchr/testify/assert/assertions.go          |  2295 +
 .../github.com/stretchr/testify/assert/doc.go      |    50 +
 .../github.com/stretchr/testify/assert/errors.go   |    10 +
 .../stretchr/testify/assert/forward_assertions.go  |    16 +
 .../stretchr/testify/assert/http_assertions.go     |   165 +
 .../stretchr/testify/assert/yaml/yaml_custom.go    |    24 +
 .../stretchr/testify/assert/yaml/yaml_default.go   |    36 +
 .../stretchr/testify/assert/yaml/yaml_fail.go      |    17 +
 backend/vendor/golang.org/x/image/LICENSE          |    27 +
 backend/vendor/golang.org/x/image/PATENTS          |    22 +
 backend/vendor/golang.org/x/image/bmp/reader.go    |   279 +
 backend/vendor/golang.org/x/image/bmp/writer.go    |   262 +
 backend/vendor/golang.org/x/image/ccitt/reader.go  |   795 +
 backend/vendor/golang.org/x/image/ccitt/table.go   |   972 +
 backend/vendor/golang.org/x/image/ccitt/writer.go  |   102 +
 backend/vendor/golang.org/x/image/draw/draw.go     |    67 +
 backend/vendor/golang.org/x/image/draw/impl.go     |  8426 ++++
 backend/vendor/golang.org/x/image/draw/scale.go    |   525 +
 .../x/image/internal/safemath/safemath.go          |    31 +
 backend/vendor/golang.org/x/image/math/f64/f64.go  |    37 +
 backend/vendor/golang.org/x/image/riff/riff.go     |   193 +
 backend/vendor/golang.org/x/image/tiff/buffer.go   |    82 +
 backend/vendor/golang.org/x/image/tiff/compress.go |    62 +
 backend/vendor/golang.org/x/image/tiff/consts.go   |   149 +
 backend/vendor/golang.org/x/image/tiff/fuzz.go     |    29 +
 .../vendor/golang.org/x/image/tiff/lzw/reader.go   |   272 +
 backend/vendor/golang.org/x/image/tiff/reader.go   |   910 +
 backend/vendor/golang.org/x/image/tiff/writer.go   |   445 +
 backend/vendor/golang.org/x/image/vp8/decode.go    |   403 +
 backend/vendor/golang.org/x/image/vp8/filter.go    |   273 +
 backend/vendor/golang.org/x/image/vp8/idct.go      |    98 +
 backend/vendor/golang.org/x/image/vp8/partition.go |   129 +
 backend/vendor/golang.org/x/image/vp8/pred.go      |   201 +
 backend/vendor/golang.org/x/image/vp8/predfunc.go  |   553 +
 backend/vendor/golang.org/x/image/vp8/quant.go     |    98 +
 .../vendor/golang.org/x/image/vp8/reconstruct.go   |   442 +
 backend/vendor/golang.org/x/image/vp8/token.go     |   381 +
 backend/vendor/golang.org/x/image/vp8l/decode.go   |   681 +
 backend/vendor/golang.org/x/image/vp8l/huffman.go  |   245 +
 .../vendor/golang.org/x/image/vp8l/transform.go    |   299 +
 backend/vendor/golang.org/x/image/webp/decode.go   |   320 +
 backend/vendor/golang.org/x/image/webp/doc.go      |     9 +
 backend/vendor/golang.org/x/net/LICENSE            |    27 +
 backend/vendor/golang.org/x/net/PATENTS            |    22 +
 backend/vendor/golang.org/x/net/html/atom/atom.go  |    78 +
 backend/vendor/golang.org/x/net/html/atom/table.go |   785 +
 backend/vendor/golang.org/x/net/html/const.go      |   111 +
 backend/vendor/golang.org/x/net/html/doc.go        |   122 +
 backend/vendor/golang.org/x/net/html/doctype.go    |   156 +
 backend/vendor/golang.org/x/net/html/entity.go     |  2252 +
 backend/vendor/golang.org/x/net/html/escape.go     |   379 +
 backend/vendor/golang.org/x/net/html/foreign.go    |   221 +
 backend/vendor/golang.org/x/net/html/iter.go       |    54 +
 backend/vendor/golang.org/x/net/html/node.go       |   230 +
 .../golang.org/x/net/html/nodetype_string.go       |    31 +
 backend/vendor/golang.org/x/net/html/parse.go      |  2378 +
 backend/vendor/golang.org/x/net/html/render.go     |   316 +
 backend/vendor/golang.org/x/net/html/token.go      |  1322 +
 backend/vendor/golang.org/x/sys/LICENSE            |    27 +
 backend/vendor/golang.org/x/sys/PATENTS            |    22 +
 backend/vendor/golang.org/x/sys/unix/.gitignore    |     2 +
 backend/vendor/golang.org/x/sys/unix/README.md     |   184 +
 .../vendor/golang.org/x/sys/unix/affinity_linux.go |   189 +
 backend/vendor/golang.org/x/sys/unix/aliases.go    |    13 +
 .../vendor/golang.org/x/sys/unix/asm_aix_ppc64.s   |    17 +
 backend/vendor/golang.org/x/sys/unix/asm_bsd_386.s |    27 +
 .../vendor/golang.org/x/sys/unix/asm_bsd_amd64.s   |    27 +
 backend/vendor/golang.org/x/sys/unix/asm_bsd_arm.s |    27 +
 .../vendor/golang.org/x/sys/unix/asm_bsd_arm64.s   |    27 +
 .../vendor/golang.org/x/sys/unix/asm_bsd_ppc64.s   |    29 +
 .../vendor/golang.org/x/sys/unix/asm_bsd_riscv64.s |    27 +
 .../vendor/golang.org/x/sys/unix/asm_linux_386.s   |    65 +
 .../vendor/golang.org/x/sys/unix/asm_linux_amd64.s |    57 +
 .../vendor/golang.org/x/sys/unix/asm_linux_arm.s   |    56 +
 .../vendor/golang.org/x/sys/unix/asm_linux_arm64.s |    50 +
 .../golang.org/x/sys/unix/asm_linux_loong64.s      |    51 +
 .../golang.org/x/sys/unix/asm_linux_mips64x.s      |    54 +
 .../vendor/golang.org/x/sys/unix/asm_linux_mipsx.s |    52 +
 .../golang.org/x/sys/unix/asm_linux_ppc64x.s       |    42 +
 .../golang.org/x/sys/unix/asm_linux_riscv64.s      |    47 +
 .../vendor/golang.org/x/sys/unix/asm_linux_s390x.s |    54 +
 .../golang.org/x/sys/unix/asm_openbsd_mips64.s     |    29 +
 .../golang.org/x/sys/unix/asm_solaris_amd64.s      |    17 +
 .../vendor/golang.org/x/sys/unix/asm_zos_s390x.s   |   382 +
 backend/vendor/golang.org/x/sys/unix/auxv.go       |    36 +
 .../golang.org/x/sys/unix/auxv_unsupported.go      |    13 +
 .../golang.org/x/sys/unix/bluetooth_linux.go       |    36 +
 backend/vendor/golang.org/x/sys/unix/bpxsvc_zos.go |   657 +
 backend/vendor/golang.org/x/sys/unix/bpxsvc_zos.s  |   192 +
 .../vendor/golang.org/x/sys/unix/cap_freebsd.go    |   195 +
 backend/vendor/golang.org/x/sys/unix/constants.go  |    13 +
 .../vendor/golang.org/x/sys/unix/dev_aix_ppc.go    |    26 +
 .../vendor/golang.org/x/sys/unix/dev_aix_ppc64.go  |    28 +
 backend/vendor/golang.org/x/sys/unix/dev_darwin.go |    24 +
 .../vendor/golang.org/x/sys/unix/dev_dragonfly.go  |    30 +
 .../vendor/golang.org/x/sys/unix/dev_freebsd.go    |    30 +
 backend/vendor/golang.org/x/sys/unix/dev_linux.go  |    42 +
 backend/vendor/golang.org/x/sys/unix/dev_netbsd.go |    29 +
 .../vendor/golang.org/x/sys/unix/dev_openbsd.go    |    29 +
 backend/vendor/golang.org/x/sys/unix/dev_zos.go    |    28 +
 backend/vendor/golang.org/x/sys/unix/dirent.go     |   102 +
 backend/vendor/golang.org/x/sys/unix/endian_big.go |     9 +
 .../vendor/golang.org/x/sys/unix/endian_little.go  |     9 +
 backend/vendor/golang.org/x/sys/unix/env_unix.go   |    31 +
 backend/vendor/golang.org/x/sys/unix/fcntl.go      |    36 +
 .../vendor/golang.org/x/sys/unix/fcntl_darwin.go   |    24 +
 .../golang.org/x/sys/unix/fcntl_linux_32bit.go     |    13 +
 backend/vendor/golang.org/x/sys/unix/fdset.go      |    27 +
 backend/vendor/golang.org/x/sys/unix/gccgo.go      |    59 +
 backend/vendor/golang.org/x/sys/unix/gccgo_c.c     |    44 +
 .../golang.org/x/sys/unix/gccgo_linux_amd64.go     |    20 +
 .../vendor/golang.org/x/sys/unix/ifreq_linux.go    |   139 +
 .../vendor/golang.org/x/sys/unix/ioctl_linux.go    |   334 +
 .../vendor/golang.org/x/sys/unix/ioctl_signed.go   |    74 +
 .../vendor/golang.org/x/sys/unix/ioctl_unsigned.go |    74 +
 backend/vendor/golang.org/x/sys/unix/ioctl_zos.go  |    71 +
 backend/vendor/golang.org/x/sys/unix/mkall.sh      |   250 +
 backend/vendor/golang.org/x/sys/unix/mkerrors.sh   |   814 +
 .../vendor/golang.org/x/sys/unix/mmap_nomremap.go  |    13 +
 backend/vendor/golang.org/x/sys/unix/mremap.go     |    57 +
 .../vendor/golang.org/x/sys/unix/pagesize_unix.go  |    15 +
 .../vendor/golang.org/x/sys/unix/pledge_openbsd.go |   111 +
 .../vendor/golang.org/x/sys/unix/ptrace_darwin.go  |    11 +
 backend/vendor/golang.org/x/sys/unix/ptrace_ios.go |    11 +
 backend/vendor/golang.org/x/sys/unix/race.go       |    30 +
 backend/vendor/golang.org/x/sys/unix/race0.go      |    25 +
 .../golang.org/x/sys/unix/readdirent_getdents.go   |    12 +
 .../x/sys/unix/readdirent_getdirentries.go         |    19 +
 backend/vendor/golang.org/x/sys/unix/readv_unix.go |   103 +
 .../golang.org/x/sys/unix/sockcmsg_dragonfly.go    |    16 +
 .../vendor/golang.org/x/sys/unix/sockcmsg_linux.go |    85 +
 .../vendor/golang.org/x/sys/unix/sockcmsg_unix.go  |   106 +
 .../golang.org/x/sys/unix/sockcmsg_unix_other.go   |    46 +
 .../vendor/golang.org/x/sys/unix/sockcmsg_zos.go   |    58 +
 .../golang.org/x/sys/unix/symaddr_zos_s390x.s      |    75 +
 backend/vendor/golang.org/x/sys/unix/syscall.go    |    86 +
 .../vendor/golang.org/x/sys/unix/syscall_aix.go    |   582 +
 .../golang.org/x/sys/unix/syscall_aix_ppc.go       |    52 +
 .../golang.org/x/sys/unix/syscall_aix_ppc64.go     |    83 +
 .../vendor/golang.org/x/sys/unix/syscall_bsd.go    |   609 +
 .../vendor/golang.org/x/sys/unix/syscall_darwin.go |   711 +
 .../golang.org/x/sys/unix/syscall_darwin_amd64.go  |    50 +
 .../golang.org/x/sys/unix/syscall_darwin_arm64.go  |    50 +
 .../x/sys/unix/syscall_darwin_libSystem.go         |    26 +
 .../golang.org/x/sys/unix/syscall_dragonfly.go     |   359 +
 .../x/sys/unix/syscall_dragonfly_amd64.go          |    56 +
 .../golang.org/x/sys/unix/syscall_freebsd.go       |   455 +
 .../golang.org/x/sys/unix/syscall_freebsd_386.go   |    64 +
 .../golang.org/x/sys/unix/syscall_freebsd_amd64.go |    64 +
 .../golang.org/x/sys/unix/syscall_freebsd_arm.go   |    60 +
 .../golang.org/x/sys/unix/syscall_freebsd_arm64.go |    60 +
 .../x/sys/unix/syscall_freebsd_riscv64.go          |    60 +
 .../vendor/golang.org/x/sys/unix/syscall_hurd.go   |    30 +
 .../golang.org/x/sys/unix/syscall_hurd_386.go      |    28 +
 .../golang.org/x/sys/unix/syscall_illumos.go       |    78 +
 .../vendor/golang.org/x/sys/unix/syscall_linux.go  |  2574 ++
 .../golang.org/x/sys/unix/syscall_linux_386.go     |   313 +
 .../golang.org/x/sys/unix/syscall_linux_alarm.go   |    12 +
 .../golang.org/x/sys/unix/syscall_linux_amd64.go   |   144 +
 .../x/sys/unix/syscall_linux_amd64_gc.go           |    12 +
 .../golang.org/x/sys/unix/syscall_linux_arm.go     |   218 +
 .../golang.org/x/sys/unix/syscall_linux_arm64.go   |   188 +
 .../golang.org/x/sys/unix/syscall_linux_gc.go      |    14 +
 .../golang.org/x/sys/unix/syscall_linux_gc_386.go  |    16 +
 .../golang.org/x/sys/unix/syscall_linux_gc_arm.go  |    13 +
 .../x/sys/unix/syscall_linux_gccgo_386.go          |    30 +
 .../x/sys/unix/syscall_linux_gccgo_arm.go          |    20 +
 .../golang.org/x/sys/unix/syscall_linux_loong64.go |   220 +
 .../golang.org/x/sys/unix/syscall_linux_mips64x.go |   187 +
 .../golang.org/x/sys/unix/syscall_linux_mipsx.go   |   173 +
 .../golang.org/x/sys/unix/syscall_linux_ppc.go     |   203 +
 .../golang.org/x/sys/unix/syscall_linux_ppc64x.go  |   114 +
 .../golang.org/x/sys/unix/syscall_linux_riscv64.go |   193 +
 .../golang.org/x/sys/unix/syscall_linux_s390x.go   |   295 +
 .../golang.org/x/sys/unix/syscall_linux_sparc64.go |   111 +
 .../vendor/golang.org/x/sys/unix/syscall_netbsd.go |   388 +
 .../golang.org/x/sys/unix/syscall_netbsd_386.go    |    37 +
 .../golang.org/x/sys/unix/syscall_netbsd_amd64.go  |    37 +
 .../golang.org/x/sys/unix/syscall_netbsd_arm.go    |    37 +
 .../golang.org/x/sys/unix/syscall_netbsd_arm64.go  |    37 +
 .../golang.org/x/sys/unix/syscall_openbsd.go       |   346 +
 .../golang.org/x/sys/unix/syscall_openbsd_386.go   |    41 +
 .../golang.org/x/sys/unix/syscall_openbsd_amd64.go |    41 +
 .../golang.org/x/sys/unix/syscall_openbsd_arm.go   |    41 +
 .../golang.org/x/sys/unix/syscall_openbsd_arm64.go |    41 +
 .../golang.org/x/sys/unix/syscall_openbsd_libc.go  |    26 +
 .../x/sys/unix/syscall_openbsd_mips64.go           |    39 +
 .../golang.org/x/sys/unix/syscall_openbsd_ppc64.go |    41 +
 .../x/sys/unix/syscall_openbsd_riscv64.go          |    41 +
 .../golang.org/x/sys/unix/syscall_solaris.go       |  1183 +
 .../golang.org/x/sys/unix/syscall_solaris_amd64.go |    27 +
 .../vendor/golang.org/x/sys/unix/syscall_unix.go   |   619 +
 .../golang.org/x/sys/unix/syscall_unix_gc.go       |    14 +
 .../x/sys/unix/syscall_unix_gc_ppc64x.go           |    22 +
 .../golang.org/x/sys/unix/syscall_zos_s390x.go     |  3213 ++
 .../vendor/golang.org/x/sys/unix/sysvshm_linux.go  |    20 +
 .../vendor/golang.org/x/sys/unix/sysvshm_unix.go   |    51 +
 .../golang.org/x/sys/unix/sysvshm_unix_other.go    |    13 +
 backend/vendor/golang.org/x/sys/unix/timestruct.go |    76 +
 .../vendor/golang.org/x/sys/unix/unveil_openbsd.go |    51 +
 .../golang.org/x/sys/unix/vgetrandom_linux.go      |    13 +
 .../x/sys/unix/vgetrandom_unsupported.go           |    11 +
 backend/vendor/golang.org/x/sys/unix/xattr_bsd.go  |   280 +
 .../golang.org/x/sys/unix/zerrors_aix_ppc.go       |  1384 +
 .../golang.org/x/sys/unix/zerrors_aix_ppc64.go     |  1385 +
 .../golang.org/x/sys/unix/zerrors_darwin_amd64.go  |  1922 +
 .../golang.org/x/sys/unix/zerrors_darwin_arm64.go  |  1922 +
 .../x/sys/unix/zerrors_dragonfly_amd64.go          |  1737 +
 .../golang.org/x/sys/unix/zerrors_freebsd_386.go   |  2042 +
 .../golang.org/x/sys/unix/zerrors_freebsd_amd64.go |  2039 +
 .../golang.org/x/sys/unix/zerrors_freebsd_arm.go   |  2033 +
 .../golang.org/x/sys/unix/zerrors_freebsd_arm64.go |  2033 +
 .../x/sys/unix/zerrors_freebsd_riscv64.go          |  2147 +
 .../vendor/golang.org/x/sys/unix/zerrors_linux.go  |  4207 ++
 .../golang.org/x/sys/unix/zerrors_linux_386.go     |   883 +
 .../golang.org/x/sys/unix/zerrors_linux_amd64.go   |   883 +
 .../golang.org/x/sys/unix/zerrors_linux_arm.go     |   888 +
 .../golang.org/x/sys/unix/zerrors_linux_arm64.go   |   885 +
 .../golang.org/x/sys/unix/zerrors_linux_loong64.go |   875 +
 .../golang.org/x/sys/unix/zerrors_linux_mips.go    |   889 +
 .../golang.org/x/sys/unix/zerrors_linux_mips64.go  |   889 +
 .../x/sys/unix/zerrors_linux_mips64le.go           |   889 +
 .../golang.org/x/sys/unix/zerrors_linux_mipsle.go  |   889 +
 .../golang.org/x/sys/unix/zerrors_linux_ppc.go     |   941 +
 .../golang.org/x/sys/unix/zerrors_linux_ppc64.go   |   945 +
 .../golang.org/x/sys/unix/zerrors_linux_ppc64le.go |   945 +
 .../golang.org/x/sys/unix/zerrors_linux_riscv64.go |   885 +
 .../golang.org/x/sys/unix/zerrors_linux_s390x.go   |   944 +
 .../golang.org/x/sys/unix/zerrors_linux_sparc64.go |   987 +
 .../golang.org/x/sys/unix/zerrors_netbsd_386.go    |  1779 +
 .../golang.org/x/sys/unix/zerrors_netbsd_amd64.go  |  1769 +
 .../golang.org/x/sys/unix/zerrors_netbsd_arm.go    |  1758 +
 .../golang.org/x/sys/unix/zerrors_netbsd_arm64.go  |  1769 +
 .../golang.org/x/sys/unix/zerrors_openbsd_386.go   |  1905 +
 .../golang.org/x/sys/unix/zerrors_openbsd_amd64.go |  1905 +
 .../golang.org/x/sys/unix/zerrors_openbsd_arm.go   |  1905 +
 .../golang.org/x/sys/unix/zerrors_openbsd_arm64.go |  1905 +
 .../x/sys/unix/zerrors_openbsd_mips64.go           |  1905 +
 .../golang.org/x/sys/unix/zerrors_openbsd_ppc64.go |  1904 +
 .../x/sys/unix/zerrors_openbsd_riscv64.go          |  1903 +
 .../golang.org/x/sys/unix/zerrors_solaris_amd64.go |  1556 +
 .../golang.org/x/sys/unix/zerrors_zos_s390x.go     |   990 +
 .../golang.org/x/sys/unix/zptrace_armnn_linux.go   |    40 +
 .../golang.org/x/sys/unix/zptrace_linux_arm64.go   |    17 +
 .../golang.org/x/sys/unix/zptrace_mipsnn_linux.go  |    49 +
 .../x/sys/unix/zptrace_mipsnnle_linux.go           |    49 +
 .../golang.org/x/sys/unix/zptrace_x86_linux.go     |    79 +
 .../golang.org/x/sys/unix/zsymaddr_zos_s390x.s     |   364 +
 .../golang.org/x/sys/unix/zsyscall_aix_ppc.go      |  1461 +
 .../golang.org/x/sys/unix/zsyscall_aix_ppc64.go    |  1420 +
 .../golang.org/x/sys/unix/zsyscall_aix_ppc64_gc.go |  1188 +
 .../x/sys/unix/zsyscall_aix_ppc64_gccgo.go         |  1069 +
 .../golang.org/x/sys/unix/zsyscall_darwin_amd64.go |  2728 ++
 .../golang.org/x/sys/unix/zsyscall_darwin_amd64.s  |   799 +
 .../golang.org/x/sys/unix/zsyscall_darwin_arm64.go |  2728 ++
 .../golang.org/x/sys/unix/zsyscall_darwin_arm64.s  |   799 +
 .../x/sys/unix/zsyscall_dragonfly_amd64.go         |  1666 +
 .../golang.org/x/sys/unix/zsyscall_freebsd_386.go  |  1886 +
 .../x/sys/unix/zsyscall_freebsd_amd64.go           |  1886 +
 .../golang.org/x/sys/unix/zsyscall_freebsd_arm.go  |  1886 +
 .../x/sys/unix/zsyscall_freebsd_arm64.go           |  1886 +
 .../x/sys/unix/zsyscall_freebsd_riscv64.go         |  1886 +
 .../x/sys/unix/zsyscall_illumos_amd64.go           |   101 +
 .../vendor/golang.org/x/sys/unix/zsyscall_linux.go |  2267 +
 .../golang.org/x/sys/unix/zsyscall_linux_386.go    |   469 +
 .../golang.org/x/sys/unix/zsyscall_linux_amd64.go  |   636 +
 .../golang.org/x/sys/unix/zsyscall_linux_arm.go    |   584 +
 .../golang.org/x/sys/unix/zsyscall_linux_arm64.go  |   535 +
 .../x/sys/unix/zsyscall_linux_loong64.go           |   469 +
 .../golang.org/x/sys/unix/zsyscall_linux_mips.go   |   636 +
 .../golang.org/x/sys/unix/zsyscall_linux_mips64.go |   630 +
 .../x/sys/unix/zsyscall_linux_mips64le.go          |   619 +
 .../golang.org/x/sys/unix/zsyscall_linux_mipsle.go |   636 +
 .../golang.org/x/sys/unix/zsyscall_linux_ppc.go    |   641 +
 .../golang.org/x/sys/unix/zsyscall_linux_ppc64.go  |   687 +
 .../x/sys/unix/zsyscall_linux_ppc64le.go           |   687 +
 .../x/sys/unix/zsyscall_linux_riscv64.go           |   531 +
 .../golang.org/x/sys/unix/zsyscall_linux_s390x.go  |   478 +
 .../x/sys/unix/zsyscall_linux_sparc64.go           |   631 +
 .../golang.org/x/sys/unix/zsyscall_netbsd_386.go   |  1848 +
 .../golang.org/x/sys/unix/zsyscall_netbsd_amd64.go |  1848 +
 .../golang.org/x/sys/unix/zsyscall_netbsd_arm.go   |  1848 +
 .../golang.org/x/sys/unix/zsyscall_netbsd_arm64.go |  1848 +
 .../golang.org/x/sys/unix/zsyscall_openbsd_386.go  |  2407 +
 .../golang.org/x/sys/unix/zsyscall_openbsd_386.s   |   719 +
 .../x/sys/unix/zsyscall_openbsd_amd64.go           |  2407 +
 .../golang.org/x/sys/unix/zsyscall_openbsd_amd64.s |   719 +
 .../golang.org/x/sys/unix/zsyscall_openbsd_arm.go  |  2407 +
 .../golang.org/x/sys/unix/zsyscall_openbsd_arm.s   |   719 +
 .../x/sys/unix/zsyscall_openbsd_arm64.go           |  2407 +
 .../golang.org/x/sys/unix/zsyscall_openbsd_arm64.s |   719 +
 .../x/sys/unix/zsyscall_openbsd_mips64.go          |  2407 +
 .../x/sys/unix/zsyscall_openbsd_mips64.s           |   719 +
 .../x/sys/unix/zsyscall_openbsd_ppc64.go           |  2407 +
 .../golang.org/x/sys/unix/zsyscall_openbsd_ppc64.s |   862 +
 .../x/sys/unix/zsyscall_openbsd_riscv64.go         |  2407 +
 .../x/sys/unix/zsyscall_openbsd_riscv64.s          |   719 +
 .../x/sys/unix/zsyscall_solaris_amd64.go           |  2217 +
 .../golang.org/x/sys/unix/zsyscall_zos_s390x.go    |  3458 ++
 .../golang.org/x/sys/unix/zsysctl_openbsd_386.go   |   280 +
 .../golang.org/x/sys/unix/zsysctl_openbsd_amd64.go |   280 +
 .../golang.org/x/sys/unix/zsysctl_openbsd_arm.go   |   280 +
 .../golang.org/x/sys/unix/zsysctl_openbsd_arm64.go |   280 +
 .../x/sys/unix/zsysctl_openbsd_mips64.go           |   280 +
 .../golang.org/x/sys/unix/zsysctl_openbsd_ppc64.go |   280 +
 .../x/sys/unix/zsysctl_openbsd_riscv64.go          |   281 +
 .../golang.org/x/sys/unix/zsysnum_darwin_amd64.go  |   439 +
 .../golang.org/x/sys/unix/zsysnum_darwin_arm64.go  |   437 +
 .../x/sys/unix/zsysnum_dragonfly_amd64.go          |   316 +
 .../golang.org/x/sys/unix/zsysnum_freebsd_386.go   |   393 +
 .../golang.org/x/sys/unix/zsysnum_freebsd_amd64.go |   393 +
 .../golang.org/x/sys/unix/zsysnum_freebsd_arm.go   |   393 +
 .../golang.org/x/sys/unix/zsysnum_freebsd_arm64.go |   393 +
 .../x/sys/unix/zsysnum_freebsd_riscv64.go          |   393 +
 .../golang.org/x/sys/unix/zsysnum_linux_386.go     |   470 +
 .../golang.org/x/sys/unix/zsysnum_linux_amd64.go   |   394 +
 .../golang.org/x/sys/unix/zsysnum_linux_arm.go     |   434 +
 .../golang.org/x/sys/unix/zsysnum_linux_arm64.go   |   337 +
 .../golang.org/x/sys/unix/zsysnum_linux_loong64.go |   334 +
 .../golang.org/x/sys/unix/zsysnum_linux_mips.go    |   454 +
 .../golang.org/x/sys/unix/zsysnum_linux_mips64.go  |   384 +
 .../x/sys/unix/zsysnum_linux_mips64le.go           |   384 +
 .../golang.org/x/sys/unix/zsysnum_linux_mipsle.go  |   454 +
 .../golang.org/x/sys/unix/zsysnum_linux_ppc.go     |   461 +
 .../golang.org/x/sys/unix/zsysnum_linux_ppc64.go   |   433 +
 .../golang.org/x/sys/unix/zsysnum_linux_ppc64le.go |   433 +
 .../golang.org/x/sys/unix/zsysnum_linux_riscv64.go |   338 +
 .../golang.org/x/sys/unix/zsysnum_linux_s390x.go   |   399 +
 .../golang.org/x/sys/unix/zsysnum_linux_sparc64.go |   413 +
 .../golang.org/x/sys/unix/zsysnum_netbsd_386.go    |   274 +
 .../golang.org/x/sys/unix/zsysnum_netbsd_amd64.go  |   274 +
 .../golang.org/x/sys/unix/zsysnum_netbsd_arm.go    |   274 +
 .../golang.org/x/sys/unix/zsysnum_netbsd_arm64.go  |   274 +
 .../golang.org/x/sys/unix/zsysnum_openbsd_386.go   |   219 +
 .../golang.org/x/sys/unix/zsysnum_openbsd_amd64.go |   219 +
 .../golang.org/x/sys/unix/zsysnum_openbsd_arm.go   |   219 +
 .../golang.org/x/sys/unix/zsysnum_openbsd_arm64.go |   218 +
 .../x/sys/unix/zsysnum_openbsd_mips64.go           |   221 +
 .../golang.org/x/sys/unix/zsysnum_openbsd_ppc64.go |   217 +
 .../x/sys/unix/zsysnum_openbsd_riscv64.go          |   218 +
 .../golang.org/x/sys/unix/zsysnum_zos_s390x.go     |  2852 ++
 .../vendor/golang.org/x/sys/unix/ztypes_aix_ppc.go |   353 +
 .../golang.org/x/sys/unix/ztypes_aix_ppc64.go      |   357 +
 .../golang.org/x/sys/unix/ztypes_darwin_amd64.go   |   878 +
 .../golang.org/x/sys/unix/ztypes_darwin_arm64.go   |   878 +
 .../x/sys/unix/ztypes_dragonfly_amd64.go           |   473 +
 .../golang.org/x/sys/unix/ztypes_freebsd_386.go    |   651 +
 .../golang.org/x/sys/unix/ztypes_freebsd_amd64.go  |   656 +
 .../golang.org/x/sys/unix/ztypes_freebsd_arm.go    |   642 +
 .../golang.org/x/sys/unix/ztypes_freebsd_arm64.go  |   636 +
 .../x/sys/unix/ztypes_freebsd_riscv64.go           |   638 +
 .../vendor/golang.org/x/sys/unix/ztypes_linux.go   |  6475 +++
 .../golang.org/x/sys/unix/ztypes_linux_386.go      |   717 +
 .../golang.org/x/sys/unix/ztypes_linux_amd64.go    |   731 +
 .../golang.org/x/sys/unix/ztypes_linux_arm.go      |   711 +
 .../golang.org/x/sys/unix/ztypes_linux_arm64.go    |   710 +
 .../golang.org/x/sys/unix/ztypes_linux_loong64.go  |   711 +
 .../golang.org/x/sys/unix/ztypes_linux_mips.go     |   716 +
 .../golang.org/x/sys/unix/ztypes_linux_mips64.go   |   713 +
 .../golang.org/x/sys/unix/ztypes_linux_mips64le.go |   713 +
 .../golang.org/x/sys/unix/ztypes_linux_mipsle.go   |   716 +
 .../golang.org/x/sys/unix/ztypes_linux_ppc.go      |   724 +
 .../golang.org/x/sys/unix/ztypes_linux_ppc64.go    |   719 +
 .../golang.org/x/sys/unix/ztypes_linux_ppc64le.go  |   719 +
 .../golang.org/x/sys/unix/ztypes_linux_riscv64.go  |   798 +
 .../golang.org/x/sys/unix/ztypes_linux_s390x.go    |   733 +
 .../golang.org/x/sys/unix/ztypes_linux_sparc64.go  |   714 +
 .../golang.org/x/sys/unix/ztypes_netbsd_386.go     |   585 +
 .../golang.org/x/sys/unix/ztypes_netbsd_amd64.go   |   593 +
 .../golang.org/x/sys/unix/ztypes_netbsd_arm.go     |   590 +
 .../golang.org/x/sys/unix/ztypes_netbsd_arm64.go   |   593 +
 .../golang.org/x/sys/unix/ztypes_openbsd_386.go    |   568 +
 .../golang.org/x/sys/unix/ztypes_openbsd_amd64.go  |   568 +
 .../golang.org/x/sys/unix/ztypes_openbsd_arm.go    |   575 +
 .../golang.org/x/sys/unix/ztypes_openbsd_arm64.go  |   568 +
 .../golang.org/x/sys/unix/ztypes_openbsd_mips64.go |   568 +
 .../golang.org/x/sys/unix/ztypes_openbsd_ppc64.go  |   570 +
 .../x/sys/unix/ztypes_openbsd_riscv64.go           |   570 +
 .../golang.org/x/sys/unix/ztypes_solaris_amd64.go  |   516 +
 .../golang.org/x/sys/unix/ztypes_zos_s390x.go      |   552 +
 backend/vendor/golang.org/x/text/LICENSE           |    27 +
 backend/vendor/golang.org/x/text/PATENTS           |    22 +
 .../golang.org/x/text/encoding/charmap/charmap.go  |   249 +
 .../golang.org/x/text/encoding/charmap/tables.go   |  7410 ++++
 .../vendor/golang.org/x/text/encoding/encoding.go  |   335 +
 .../golang.org/x/text/encoding/ianaindex/ascii.go  |    74 +
 .../x/text/encoding/ianaindex/ianaindex.go         |   214 +
 .../golang.org/x/text/encoding/ianaindex/tables.go |  2355 +
 .../encoding/internal/identifier/identifier.go     |    81 +
 .../x/text/encoding/internal/identifier/mib.go     |  1627 +
 .../x/text/encoding/internal/internal.go           |    75 +
 .../golang.org/x/text/encoding/japanese/all.go     |    12 +
 .../golang.org/x/text/encoding/japanese/eucjp.go   |   225 +
 .../x/text/encoding/japanese/iso2022jp.go          |   299 +
 .../x/text/encoding/japanese/shiftjis.go           |   189 +
 .../golang.org/x/text/encoding/japanese/tables.go  | 26971 ++++++++++++
 .../golang.org/x/text/encoding/korean/euckr.go     |   177 +
 .../golang.org/x/text/encoding/korean/tables.go    | 34152 ++++++++++++++
 .../x/text/encoding/simplifiedchinese/all.go       |    12 +
 .../x/text/encoding/simplifiedchinese/gbk.go       |   273 +
 .../x/text/encoding/simplifiedchinese/hzgb2312.go  |   245 +
 .../x/text/encoding/simplifiedchinese/tables.go    | 43999 +++++++++++++++++++
 .../x/text/encoding/traditionalchinese/big5.go     |   199 +
 .../x/text/encoding/traditionalchinese/tables.go   | 37142 ++++++++++++++++
 .../golang.org/x/text/encoding/unicode/override.go |    82 +
 .../golang.org/x/text/encoding/unicode/unicode.go  |   512 +
 .../x/text/internal/utf8internal/utf8internal.go   |    87 +
 backend/vendor/golang.org/x/text/runes/cond.go     |   187 +
 backend/vendor/golang.org/x/text/runes/runes.go    |   355 +
 .../golang.org/x/text/transform/transform.go       |   709 +
 backend/vendor/golang.org/x/xerrors/LICENSE        |    27 +
 backend/vendor/golang.org/x/xerrors/PATENTS        |    22 +
 backend/vendor/golang.org/x/xerrors/README         |     2 +
 backend/vendor/golang.org/x/xerrors/adaptor.go     |   193 +
 backend/vendor/golang.org/x/xerrors/codereview.cfg |     1 +
 backend/vendor/golang.org/x/xerrors/doc.go         |    22 +
 backend/vendor/golang.org/x/xerrors/errors.go      |    33 +
 backend/vendor/golang.org/x/xerrors/fmt.go         |   187 +
 backend/vendor/golang.org/x/xerrors/format.go      |    34 +
 backend/vendor/golang.org/x/xerrors/frame.go       |    56 +
 .../golang.org/x/xerrors/internal/internal.go      |     8 +
 backend/vendor/golang.org/x/xerrors/wrap.go        |   106 +
 backend/vendor/gopkg.in/yaml.v3/LICENSE            |    50 +
 backend/vendor/gopkg.in/yaml.v3/NOTICE             |    13 +
 backend/vendor/gopkg.in/yaml.v3/README.md          |   150 +
 backend/vendor/gopkg.in/yaml.v3/apic.go            |   747 +
 backend/vendor/gopkg.in/yaml.v3/decode.go          |  1000 +
 backend/vendor/gopkg.in/yaml.v3/emitterc.go        |  2020 +
 backend/vendor/gopkg.in/yaml.v3/encode.go          |   577 +
 backend/vendor/gopkg.in/yaml.v3/parserc.go         |  1258 +
 backend/vendor/gopkg.in/yaml.v3/readerc.go         |   434 +
 backend/vendor/gopkg.in/yaml.v3/resolve.go         |   326 +
 backend/vendor/gopkg.in/yaml.v3/scannerc.go        |  3038 ++
 backend/vendor/gopkg.in/yaml.v3/sorter.go          |   134 +
 backend/vendor/gopkg.in/yaml.v3/writerc.go         |    48 +
 backend/vendor/gopkg.in/yaml.v3/yaml.go            |   698 +
 backend/vendor/gopkg.in/yaml.v3/yamlh.go           |   807 +
 backend/vendor/gopkg.in/yaml.v3/yamlprivateh.go    |   198 +
 backend/vendor/modules.txt                         |    83 +
 cli.sh                                             |   623 -
 config/Config.qml                                  |   560 +-
 config/KeybindActions.js                           |    22 +-
 config/defaults/general.js                         |     7 +
 config/defaults/system.js                          |   126 +-
 docs/MEMORY_AUDIT.md                               |   139 +
 flake.lock                                         |    12 +-
 flake.nix                                          |     6 +-
 install.sh                                         |   121 +-
 modules/bar/BatteryIndicator.qml                   |    20 +-
 modules/bar/BrightnessSlider.qml                   |   181 -
 modules/bar/IntegratedDockAppButton.qml            |     4 +-
 modules/bar/LayoutSelectorButton.qml               |    23 +-
 modules/bar/PowerProfileSelector.qml               |    28 +-
 modules/bar/clock/Pomodoro.qml                     |    54 +-
 modules/components/BarPopup.qml                    |    22 +
 modules/globals/GlobalStates.qml                   |    28 +-
 modules/notch/NotchContent.qml                     |     4 +-
 modules/services/AGENTS.md                         |     2 +-
 modules/services/Ai.qml                            |    52 +-
 modules/services/AppSearch.qml                     |    29 +-
 modules/services/Audio.qml                         |    11 +-
 modules/services/AxctlService.qml                  |   142 +-
 modules/services/BackendService.qml                |   210 +
 modules/services/Battery.qml                       |    65 +
 modules/services/Brightness.qml                    |   354 +-
 modules/services/CaffeineClient.qml                |    30 +
 modules/services/CaffeineService.qml               |    42 -
 modules/services/ClipboardService.qml              |   161 +-
 modules/services/CompositorConfig.qml              |   259 +-
 modules/services/CompositorTomlWriter.qml          |   778 +-
 modules/services/DesktopService.qml                |    70 +-
 modules/services/GameModeClient.qml                |    37 +
 modules/services/GameModeService.qml               |   140 -
 modules/services/GlobalShortcuts.qml               |    35 +-
 modules/services/IdleInhibitor.qml                 |    95 -
 modules/services/IdleService.qml                   |    86 +-
 modules/services/KeyStore.qml                      |   105 +-
 modules/services/MprisController.qml               |    14 +-
 modules/services/NetworkService.qml                |   333 +-
 modules/services/NightLightClient.qml              |    43 +
 modules/services/NightLightService.qml             |    96 -
 modules/services/Notifications.qml                 |   147 +-
 modules/services/PowerProfile.qml                  |   325 -
 modules/services/PowerProfileClient.qml            |    67 +
 modules/services/PresetCommandService.qml          |    34 +
 modules/services/PresetsService.qml                |    25 +-
 modules/services/ScreenRecorder.qml                |   263 +-
 modules/services/Screenshot.qml                    |   451 +-
 modules/services/StateService.qml                  |    84 +-
 modules/services/SystemResources.qml               |   157 +-
 modules/services/TaskbarApps.qml                   |     3 +-
 modules/services/TerminalService.qml               |    29 +
 modules/services/UpdateService.qml                 |    52 +-
 modules/services/Visibilities.qml                  |    32 +
 modules/services/WallpaperCommandService.qml       |   171 +
 modules/services/WeatherService.qml                |   225 +-
 modules/theme/AGENTS.md                            |     1 +
 modules/theme/Colors.qml                           |     5 +
 modules/theme/GtkGenerator.qml                     |    17 +-
 modules/theme/Icons.qml                            |     1 +
 modules/theme/NvChadGenerator.qml                  |    16 +-
 modules/theme/PywalZenGenerator.qml                |    76 +
 modules/tools/ScreenshotTool.qml                   |     9 +-
 modules/widgets/config/SettingsWindow.qml          |    74 +-
 modules/widgets/dashboard/Dashboard.qml            |    18 +-
 modules/widgets/dashboard/DashboardView.qml        |     6 +-
 modules/widgets/dashboard/controls/SystemPanel.qml |   112 +-
 modules/widgets/dashboard/tmux/TmuxTab.qml         |    33 +-
 modules/widgets/dashboard/wallpapers/Wallpaper.qml |    40 +-
 .../widgets/dashboard/wallpapers/WallpapersTab.qml |     5 +-
 modules/widgets/dashboard/widgets/FullPlayer.qml   |     1 +
 .../widgets/dashboard/widgets/QuickControls.qml    |    18 +-
 .../dashboard/widgets/calendar/Calendar.qml        |    14 +-
 .../widgets/dashboard/widgets/calendar/layout.js   |     4 +-
 modules/widgets/tools/ToolsMenu.qml                |    63 +-
 nix/packages/apps.nix                              |     4 +-
 nix/packages/backend.nix                           |    28 +
 nix/packages/default.nix                           |    14 +-
 nix/packages/tools.nix                             |     5 -
 scripts/AGENTS.md                                  |    46 +-
 scripts/brightness_list.sh                         |    44 -
 scripts/clipboard_watch.sh                         |    28 -
 scripts/colorpicker.py                             |   114 -
 scripts/daemon_priority.sh                         |    18 -
 scripts/desktop_thumbgen.py                        |   268 -
 scripts/google_lens.sh                             |     4 +-
 scripts/keystore.py                                |   151 -
 scripts/link_preview.py                            |   355 -
 scripts/lockwall.py                                |   149 -
 scripts/loginlock.sh                               |    30 -
 scripts/ocr.sh                                     |    40 -
 scripts/qr_scan.sh                                 |    29 -
 scripts/sleep_monitor.sh                           |    53 -
 scripts/system_monitor.py                          |   328 -
 scripts/thumbgen.py                                |   415 -
 scripts/weather.sh                                 |   140 -
 scripts/wf-record.sh                               |   119 -
 shell.qml                                          |    19 +-
 version                                            |     2 +-
 860 files changed, 475527 insertions(+), 6454 deletions(-)

## Combined diff
diff --cc config/Config.qml
index 08779295,41436c75..32e5b1bb
--- a/config/Config.qml
+++ b/config/Config.qml
@@@ -14,21 -14,21 +14,22 @@@ import "defaults/notch.js" as NotchDefa
  import "defaults/compositor.js" as CompositorDefaults
  import "KeybindActions.js" as KeybindActions
  import "defaults/performance.js" as PerformanceDefaults
  import "defaults/weather.js" as WeatherDefaults
  import "defaults/desktop.js" as DesktopDefaults
  import "defaults/lockscreen.js" as LockscreenDefaults
  import "defaults/prefix.js" as PrefixDefaults
  import "defaults/system.js" as SystemDefaults
  import "defaults/dock.js" as DockDefaults
  import "defaults/ai.js" as AiDefaults
 +import "defaults/calendar.js" as CalendarDefaults
+ import "defaults/general.js" as GeneralDefaults
  import "ConfigValidator.js" as ConfigValidator
  
  Singleton {
      id: root
  
      property string version: "0.0.0"
  
      FileView {
          id: versionFile
          path: Qt.resolvedUrl("../version").toString().replace("file://", "")
@@@ -49,24 -49,24 +50,25 @@@
      property bool notchReady: false
      property bool compositorReady: false
      property bool performanceReady: false
      property bool weatherReady: false
      property bool desktopReady: false
      property bool lockscreenReady: false
      property bool prefixReady: false
      property bool systemReady: false
      property bool dockReady: false
      property bool aiReady: false
 +    property bool calendarReady: false
+     property bool generalReady: false
      property bool keybindsInitialLoadComplete: false
  
-     property bool initialLoadComplete: themeReady && barReady && workspacesReady && overviewReady && notchReady && compositorReady && performanceReady && weatherReady && desktopReady && lockscreenReady && prefixReady && systemReady && dockReady && aiReady && calendarReady
 -    property bool initialLoadComplete: themeReady && barReady && workspacesReady && overviewReady && notchReady && compositorReady && performanceReady && weatherReady && desktopReady && lockscreenReady && prefixReady && systemReady && dockReady && aiReady && generalReady
++    property bool initialLoadComplete: themeReady && barReady && workspacesReady && overviewReady && notchReady && compositorReady && performanceReady && weatherReady && desktopReady && lockscreenReady && prefixReady && systemReady && dockReady && aiReady && calendarReady && generalReady
  
      // Compatibility aliases
      property alias loader: themeLoader
      property alias keybindsLoader: keybindsLoader
  
      // ============================================
      // BATCH INITIALIZATION
      // ============================================
      // Ensure config directory exists and copy preset files if missing
      Process {
@@@ -1202,72 -1180,61 +1204,113 @@@
              property string systemPrompt: "You are a helpful assistant running on a Linux system. You have access to some tools to control the system."
              property string tool: "none"
              property list<var> extraModels: []
              property string defaultModel: "gemini-2.0-flash"
              property int sidebarWidth: 400
              property string sidebarPosition: "right"
              property bool sidebarPinnedOnStartup: false
          }
      }
  
 +    // ============================================
 +    // CALENDAR MODULE
 +    // ============================================
 +    FileView {
 +        id: calendarLoader
 +        path: root.configDir + "/calendar.json"
 +        atomicWrites: true
 +        watchChanges: true
 +        onLoaded: {
 +            if (!root.calendarReady) {
 +                validateModule("calendar", calendarLoader, CalendarDefaults.data, () => {
 +                    root.calendarReady = true;
 +                });
 +            }
 +        }
 +        onLoadFailed: {
 +            if (error.toString().includes("FileNotFound") && !root.calendarReady) {
 +                handleMissingConfig("calendar", calendarLoader, CalendarDefaults.data, () => {
 +                    root.calendarReady = true;
 +                });
 +            }
 +        }
 +        onFileChanged: {
 +            root.pauseAutoSave = true;
 +            reload();
 +            root.pauseAutoSave = false;
 +        }
 +        onPathChanged: reload()
 +        onAdapterUpdated: {
 +            if (root.calendarReady && !root.pauseAutoSave) {
 +                calendarLoader.writeAdapter();
 +            }
 +        }
 +
 +        adapter: JsonAdapter {
 +            property bool enabled: true
 +            property int syncInterval: 15
 +            property bool notifications: true
 +            property bool barIndicator: true
 +            property bool barShowNextEvent: false
 +            property int defaultReminder: 15
 +            property string googleClientId: ""
 +            property string googleClientSecret: ""
 +            property list<var> accounts: []
 +            property var calendars: ({})
 +            property bool soundOnArrival: true
 +            property bool blinkOnArrival: true
 +            property string arrivalSoundPath: ""
 +            property bool barAlwaysShow: false
 +        }
 +    }
 +
+     // ============================================
+     // GENERAL MODULE
+     // ============================================
+     FileView {
+         id: generalLoader
+         path: root.configDir + "/general.json"
+         atomicWrites: true
+         watchChanges: true
+         onLoaded: {
+             if (!root.generalReady) {
+                 validateModule("general", generalLoader, GeneralDefaults.data, () => {
+                     root.generalReady = true;
+                 });
+             }
+         }
+         onLoadFailed: {
+             if (error.toString().includes("FileNotFound") && !root.generalReady) {
+                 handleMissingConfig("general", generalLoader, GeneralDefaults.data, () => {
+                     root.generalReady = true;
+                 });
+             }
+         }
+         onFileChanged: {
+             root.pauseAutoSave = true;
+             reload();
+             root.pauseAutoSave = false;
+         }
+         onPathChanged: reload()
+         onAdapterUpdated: {
+             if (root.generalReady && !root.pauseAutoSave) {
+                 generalLoader.writeAdapter();
+             }
+         }
+ 
+         adapter: JsonAdapter {
+             property string terminal: "kitty"
+             property bool terminalAdvanced: false
+             property string terminalCommand: "$TERMINAL -e $COMMAND"
+         }
+     }
+ 
      // Keybinds (binds.json)
      // Timer to repair keybinds after initial load
      Timer {
          id: repairKeybindsTimer
          interval: 500
          repeat: false
          onTriggered: {
              repairKeybinds();
          }
      }
@@@ -3400,23 -3500,23 +3576,26 @@@
  
      // Dock configuration
      property QtObject dock: dockLoader.adapter
  
      // Pinned apps configuration (stored in dataPath)
      property QtObject pinnedApps: pinnedAppsLoader.adapter
  
      // AI configuration
      property QtObject ai: aiLoader.adapter
  
 +    // Calendar configuration
 +    property QtObject calendar: calendarLoader.adapter
 +
+     // General configuration
+     property QtObject general: generalLoader.adapter
+ 
      // Module save functions
      function saveBar() {
          barLoader.writeAdapter();
      }
      function saveWorkspaces() {
          workspacesLoader.writeAdapter();
      }
      function saveOverview() {
          overviewLoader.writeAdapter();
      }
@@@ -3446,23 -3546,23 +3625,26 @@@
      }
      function saveDock() {
          dockLoader.writeAdapter();
      }
      function savePinnedApps() {
          pinnedAppsLoader.writeAdapter();
      }
      function saveAi() {
          aiLoader.writeAdapter();
      }
 +    function saveCalendar() {
 +        calendarLoader.writeAdapter();
 +    }
+     function saveGeneral() {
+         generalLoader.writeAdapter();
+     }
  
      // Color helpers
      function isHexColor(colorValue) {
          if (!colorValue || typeof colorValue !== 'string')
              return false;
          const normalized = colorValue.toLowerCase().trim();
          return normalized.startsWith('#') || normalized.startsWith('rgb');
      }
  
      function resolveColor(colorValue) {
diff --cc config/defaults/system.js
index ac9e59e5,07d6e187..8b61ff4e
--- a/config/defaults/system.js
+++ b/config/defaults/system.js
@@@ -1,67 -1,48 +1,67 @@@
  .pragma library
  
  var data = {
- 	"disks": ["/"],
- 	"updateServiceEnabled": true,
- 	"idle": {
- 		"general": {
- 			"lock_cmd": "ambxst lock",
- 			"before_sleep_cmd": "loginctl lock-session",
- 			"after_sleep_cmd": "ambxst screen on"
- 		},
- 		"listeners": [
- 			{
- 				"timeout": 150,
- 				"onTimeout": "ambxst brightness 10 -s",
- 				"onResume": "ambxst brightness -r"
- 			},
- 			{
- 				"timeout": 300,
- 				"onTimeout": "loginctl lock-session"
- 			},
- 			{
- 				"timeout": 330,
- 				"onTimeout": "ambxst screen off",
- 				"onResume": "ambxst screen on"
- 			},
- 			{
- 				"timeout": 1800,
- 				"onTimeout": "ambxst suspend"
- 			}
- 		]
- 	},
- 	"ocr": {
- 		"eng": true,
- 		"spa": true,
- 		"lat": false,
- 		"jpn": false,
- 		"chi_sim": false,
- 		"chi_tra": false,
- 		"kor": false,
- 		"rus": false
- 	},
- 	"pomodoro": {
- 		"workTime": 1500,
- 		"restTime": 300,
- 		"autoStart": false,
- 		"syncSpotify": false
- 	},
- 	"language": "auto",
- 	"resources": {
- 		"enabled": true,
- 		"location": "dashboard",
- 		"barSide": "left",
- 		"show": {
- 			"cpu": true,
- 			"ram": true,
- 			"gpu": true,
- 			"disk": true,
- 			"barCpu": true,
- 			"barRam": true,
- 			"barGpu": true,
- 			"barDisk": true,
- 			"dashTemp": true,
- 			"barTemp": true
- 		}
- 	}
+     "disks": ["/"],
+     "updateServiceEnabled": true,
+     "idle": {
+         "general": {
+             "lock_cmd": "ambxst lock",
+             "before_sleep_cmd": "loginctl lock-session",
+             "after_sleep_cmd": "ambxst screen on"
+         },
+         "listeners": [
+             {
+                 "timeout": 150,
+                 "onTimeout": "axctl brightness save && axctl brightness set 0.1",
+                 "onResume": "axctl brightness restore"
+             },
+             {
+                 "timeout": 300,
+                 "onTimeout": "loginctl lock-session"
+             },
+             {
+                 "timeout": 330,
+                 "onTimeout": "ambxst screen off",
+                 "onResume": "ambxst screen on"
+             },
+             {
+                 "timeout": 1800,
+                 "onTimeout": "ambxst suspend"
+             }
+         ]
+     },
+     "ocr": {
+         "eng": true,
+         "spa": true,
+         "lat": false,
+         "jpn": false,
+         "chi_sim": false,
+         "chi_tra": false,
 -        "kor": false
++        "kor": false,
++        "rus": false
+     },
+     "pomodoro": {
+         "workTime": 1500,
+         "restTime": 300,
+         "autoStart": false,
+         "syncSpotify": false
++    },
++    "language": "auto",
++    "resources": {
++        "enabled": true,
++        "location": "dashboard",
++        "barSide": "left",
++        "show": {
++            "cpu": true,
++            "ram": true,
++            "gpu": true,
++            "disk": true,
++            "barCpu": true,
++            "barRam": true,
++            "barGpu": true,
++            "barDisk": true,
++            "dashTemp": true,
++            "barTemp": true
++        }
+     }
  }
diff --cc modules/bar/BatteryIndicator.qml
index 873a45ac,c3fcb229..27dfccf8
--- a/modules/bar/BatteryIndicator.qml
+++ b/modules/bar/BatteryIndicator.qml
@@@ -179,21 -179,21 +179,21 @@@ Item 
          }
  
          MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: batteryPopup.toggle()
          }
  
          StyledToolTip {
              visible: root.isHovered && !root.popupOpen
-             tooltipText: Battery.available ? I18n.t("battery.status", Math.round(Battery.percentage)) : I18n.t("battery.power_profile", PowerProfile.getProfileDisplayName(PowerProfile.currentProfile))
 -            tooltipText: Battery.available ? ("Battery: " + Math.round(Battery.percentage) + "%" + (Battery.isCharging ? " (Charging)" : "")) : ("Power Profile: " + PowerProfileClient.getProfileDisplayName(PowerProfileClient.currentProfile))
++            tooltipText: Battery.available ? (I18n.t("battery.status", Math.round(Battery.percentage)) + (Battery.isCharging ? " (" + I18n.t("battery.charging") + ")" : "")) : I18n.t("battery.power_profile", PowerProfileClient.getProfileDisplayName(PowerProfileClient.currentProfile))
          }
      }
  
      // Battery popup with Power Profiles
      BarPopup {
          id: batteryPopup
          anchorItem: buttonBg
          bar: root.bar
  
          contentWidth: Math.max(280, mainColumn.implicitWidth + batteryPopup.popupPadding * 2)
diff --cc modules/bar/LayoutSelectorButton.qml
index ebb9a0f1,a523e24b..d500e29a
--- a/modules/bar/LayoutSelectorButton.qml
+++ b/modules/bar/LayoutSelectorButton.qml
@@@ -96,35 -100,35 +100,35 @@@ Item 
  
          MouseArea {
              anchors.fill: parent
              hoverEnabled: false
              cursorShape: Qt.PointingHandCursor
              onClicked: layoutPopup.toggle()
          }
  
          StyledToolTip {
              visible: root.isHovered && !root.popupOpen
 -            tooltipText: "Layout: " + root.getLayoutDisplayName(GlobalStates.compositorLayout)
 +            tooltipText: I18n.t("bar.tooltip.layout", root.getLayoutDisplayName(GlobalStates.compositorLayout))
          }
      }
  
      // Layout popup
      BarPopup {
          id: layoutPopup
          anchorItem: buttonBg
          bar: root.bar
  
-         contentWidth: layoutRow.implicitWidth + popupPadding * 2
-         contentHeight: 36 + popupPadding * 2
+         contentWidth: layoutColumn.implicitWidth + popupPadding * 2
+         contentHeight: layoutColumn.implicitHeight + popupPadding * 2
  
-         Row {
-             id: layoutRow
+         ColumnLayout {
+             id: layoutColumn
              anchors.centerIn: parent
              spacing: 4
  
              readonly property int currentIndex: {
                  for (let i = 0; i < GlobalStates.availableLayouts.length; i++) {
                      if (GlobalStates.availableLayouts[i] === GlobalStates.compositorLayout) {
                          return i;
                      }
                  }
                  return 0;
diff --cc modules/services/PowerProfileClient.qml
index 00000000,09145781..8c493095
mode 000000,100644..100644
--- a/modules/services/PowerProfileClient.qml
+++ b/modules/services/PowerProfileClient.qml
@@@ -1,0 -1,67 +1,67 @@@
+ import QtQuick
+ import Quickshell
+ import qs.modules.theme
+ 
+ pragma Singleton
+ 
+ Singleton {
+     id: root
+ 
+     property var availableProfiles: []
+     property string currentProfile: ""
+     property bool isAvailable: false
+     property string backendType: ""
+     property int subHandle: -1
+ 
+     function refresh() {
+         BackendService.call("powerprofile.current", {}, (cur, cerr) => {
+             if (cerr || !cur) return;
+             Qt.callLater(() => {
+                 root.isAvailable = cur.available === true;
+                 root.backendType = cur.backend || "";
+                 root.currentProfile = cur.profile || "";
+             });
+         });
+         BackendService.call("powerprofile.available", {}, (avail, aerr) => {
+             if (aerr || !avail) return;
+             Qt.callLater(() => {
+                 root.isAvailable = avail.available === true;
+                 root.backendType = avail.backend || "";
+                 root.availableProfiles = avail.profiles || [];
+                 if (!root.currentProfile && avail.profile)
+                     root.currentProfile = avail.profile;
+             });
+         });
+     }
+ 
+     function setProfile(profile) {
+         BackendService.call("powerprofile.set", {profile: profile});
+     }
+ 
+     function getProfileIcon(name) {
+         if (name === "power-saver") return Icons.powerSave;
+         if (name === "balanced") return Icons.balanced;
+         if (name === "performance") return Icons.performance;
+         return Icons.balanced;
+     }
+ 
+     function getProfileDisplayName(name) {
 -        if (name === "power-saver") return "Power Save";
 -        if (name === "balanced") return "Balanced";
 -        if (name === "performance") return "Performance";
++        if (name === "power-saver") return I18n.t("power_profile.power_save");
++        if (name === "balanced") return I18n.t("power_profile.balanced");
++        if (name === "performance") return I18n.t("power_profile.performance");
+         return name || "";
+     }
+ 
+     Component.onCompleted: {
+         root.refresh();
+         root.subHandle = BackendService.addSubscription(["powerprofile"], (service, data) => {
+             if (service !== "powerprofile.state" || !data) return;
+             Qt.callLater(() => {
+                 root.isAvailable = data.available === true;
+                 root.backendType = data.backend || "";
+                 root.currentProfile = data.profile || "";
+                 root.availableProfiles = data.profiles || [];
+             });
+         });
+     }
+ }
diff --cc modules/services/SystemResources.qml
index 51111674,f14ab811..9aaa0c21
--- a/modules/services/SystemResources.qml
+++ b/modules/services/SystemResources.qml
@@@ -47,98 -47,110 +47,113 @@@ Singleton 
      property var ramHistory: []
      property var gpuHistories: []
      property var cpuTempHistory: []
      property var gpuTempHistories: []
      property int maxHistoryPoints: 50
      property int totalDataPoints: 0
  
      // Update interval
      property int updateInterval: 2000
  
-     // Unified monitor process.
-     // When location = "dashboard": only runs while the metrics tab is open — fully lazy.
-     // When location = "bar" or "both": runs continuously for the session so the bar
-     // widget stays live. This is a deliberate trade-off: the python script still uses
-     // the is_active power-state check to avoid polling an idle dGPU, but the process
-     // itself stays alive and polls CPU/RAM/disk at updateInterval ms regardless of
-     // bar visibility.
-     property Process monitorProcess: Process {
-         id: monitorProcess
-         running: (Config.system.resources && Config.system.resources.enabled !== false) && ((GlobalStates.dashboardOpen && GlobalStates.dashboardCurrentTab === 2) || Config.system.resources.location === "bar" || Config.system.resources.location === "both") && root.validDisks.length > 0
-         
-         command: {
-             let cmd = ["python3", Quickshell.shellDir + "/scripts/system_monitor.py", root.updateInterval.toString()];
-             return cmd.concat(root.validDisks);
+     property int subscriptionHandle: -1
+ 
 -    // Subscription only lives while the dashboard Metrics tab is open,
++    // Subscription activation.
++    // When location = "dashboard": only lives while the metrics tab is open — fully lazy,
+     // preserving the original resource-saving behaviour (no dGPU polling).
 -    readonly property bool monitoringActive: GlobalStates.dashboardOpen && GlobalStates.dashboardCurrentTab === 2 && root.validDisks.length > 0
++    // When location = "bar" or "both": stays active for the whole session so the bar
++    // widget stays live, even while the dashboard is closed.
++    readonly property bool monitoringActive: (Config.system.resources && Config.system.resources.enabled !== false) && ((GlobalStates.dashboardOpen && GlobalStates.dashboardCurrentTab === 2) || Config.system.resources.location === "bar" || Config.system.resources.location === "both") && root.validDisks.length > 0
+ 
+     onMonitoringActiveChanged: {
+         if (monitoringActive) activateMonitor();
+         else deactivateMonitor();
+     }
+ 
+     onValidDisksChanged: {
+         if (monitoringActive) {
+             deactivateMonitor();
+             Qt.callLater(() => activateMonitor());
          }
-         
-         stdout: SplitParser {
-             onRead: data => {
-                 try {
-                     const stats = JSON.parse(data);
-                     
-                     // Static info (received once at start)
-                     if (stats.static) {
-                         root.cpuModel = stats.static.cpu_model || root.cpuModel;
-                         root.gpuNames = stats.static.gpu_names || [];
-                         root.gpuVendors = stats.static.gpu_vendors || [];
-                         root.gpuCount = stats.static.gpu_count || 0;
-                         root.gpuDetected = root.gpuCount > 0;
-                         root.diskTypes = stats.static.disk_types || {};
-                         return;
-                     }
- 
-                     // Update metrics
-                     if (stats.cpu) {
-                         root.cpuUsage = stats.cpu.usage;
-                         root.cpuTemp = stats.cpu.temp;
-                     }
-                     
-                     if (stats.ram) {
-                         root.ramUsage = stats.ram.usage;
-                         root.ramTotal = stats.ram.total;
-                         root.ramUsed = stats.ram.used;
-                         root.ramAvailable = stats.ram.available;
-                     }
-                     
-                     if (stats.disk) root.diskUsage = stats.disk.usage;
-                     
-                     if (stats.gpu) {
-                         root.gpuUsages = stats.gpu.usages;
-                         root.gpuTemps = stats.gpu.temps;
-                     }
-                     
-                     root.updateHistory();
-                 } catch (e) {
-                     console.warn("SystemResources: Failed to parse monitor data: " + e);
-                 }
+     }
+ 
+     onUpdateIntervalChanged: if (monitoringActive) updateConfigure()
+ 
+     Component.onCompleted: {
+         validateDisks();
+         root.subscriptionHandle = BackendService.addSubscription(["systemmonitor"], (service, data) => root.handleEvent(service, data));
+         if (monitoringActive) activateMonitor();
+     }
+ 
+     function activateMonitor() {
+         if (root.subscriptionHandle < 0) return;
+         root.updateConfigure();
+         BackendService.setSubscriptionActive(root.subscriptionHandle, true);
+     }
+ 
+     function deactivateMonitor() {
+         if (root.subscriptionHandle < 0) return;
+         BackendService.setSubscriptionActive(root.subscriptionHandle, false);
+     }
+ 
+     function updateConfigure() {
+         BackendService.call("systemmonitor.configure", {
+             interval_ms: Math.max(100, root.updateInterval),
+             disks: root.validDisks.length > 0 ? root.validDisks : ["/"]
+         });
+     }
+ 
+     function handleEvent(service, data) {
+         if (service !== "systemmonitor" && service !== "systemmonitor.static") return;
+         try {
+             if (service === "systemmonitor.static") {
+                 root.cpuModel = data.cpu_model || root.cpuModel;
+                 root.gpuNames = data.gpu_names || [];
+                 root.gpuVendors = data.gpu_vendors || [];
+                 root.gpuCount = data.gpu_count || 0;
+                 root.gpuDetected = root.gpuCount > 0;
+                 root.diskTypes = data.disk_types || {};
+                 return;
              }
+ 
+             if (data.cpu) {
+                 root.cpuUsage = data.cpu.usage;
+                 root.cpuTemp = data.cpu.temp;
+             }
+ 
+             if (data.ram) {
+                 root.ramUsage = data.ram.usage;
+                 root.ramTotal = data.ram.total;
+                 root.ramUsed = data.ram.used;
+                 root.ramAvailable = data.ram.available;
+             }
+ 
+             if (data.disk) root.diskUsage = data.disk.usage;
+ 
+             if (data.gpu) {
+                 root.gpuUsages = data.gpu.usages;
+                 root.gpuTemps = data.gpu.temps;
+             }
+ 
+             root.updateHistory();
+         } catch (e) {
+             console.warn("SystemResources: Failed to parse monitor data: " + e);
          }
      }
  
-     Component.onCompleted: validateDisks()
- 
      Connections {
          target: Config.system
          function onDisksChanged() { root.validateDisks(); }
      }
  
      property bool configReady: Config.initialLoadComplete
      onConfigReadyChanged: if (configReady) validateDisks()
  
-     onValidDisksChanged: if (monitorProcess.running) restartMonitor()
-     onUpdateIntervalChanged: if (monitorProcess.running) restartMonitor()
- 
-     function restartMonitor() {
-         monitorProcess.running = false;
-         Qt.callLater(() => { monitorProcess.running = true; });
-     }
- 
      function validateDisks() {
          const configuredDisks = Config.system.disks || ["/"];
          let newValidDisks = [];
          for (let i = 0; i < configuredDisks.length; i++) {
              const disk = configuredDisks[i];
              if (disk && typeof disk === 'string' && disk.trim() !== '') {
                  newValidDisks.push(disk.trim());
              }
          }
          if (newValidDisks.length === 0) newValidDisks = ["/"];
diff --cc modules/services/WeatherService.qml
index 2a4b7384,9eceffa4..0934b31b
--- a/modules/services/WeatherService.qml
+++ b/modules/services/WeatherService.qml
@@@ -373,134 -370,101 +370,110 @@@ Singleton 
          if (retryCount < maxRetries) {
              retryCount++;
              retryTimer.start();
          } else {
              root.isLoading = false;
              root.hasFailed = true;
              retryCount = 0;
          }
      }
  
-     property Process weatherProcess: Process {
-         running: false
-         command: []
+     // Processes the daemon response for weather.get.
+     function handleResponse(data) {
+         if (!data) {
+             console.warn("WeatherService: Empty response");
+             root.dataAvailable = false;
+             root.handleError();
+             return;
+         }
+ 
+         try {
+             // Check for error payload
+             if (data.error) {
+                 console.warn("WeatherService:", data.error);
+                 root.dataAvailable = false;
+                 root.handleError();
+                 return;
+             }
+ 
+             if (data.current_weather && data.daily) {
+                 var weather = data.current_weather;
+                 var daily = data.daily;
+ 
+                 root.weatherCode = parseInt(weather.weathercode);
+                 root.currentTemp = convertTemp(parseFloat(weather.temperature));
+                 root.windSpeed = parseFloat(weather.windspeed);
  
-         stdout: StdioCollector {
-             waitForEnd: true
-             onStreamFinished: {
-                 // Skip processing if we cancelled this request
-                 if (root.wasCancelled) {
-                     return;
+                 if (daily.temperature_2m_max && daily.temperature_2m_max.length > 0) {
+                     root.maxTemp = convertTemp(parseFloat(daily.temperature_2m_max[0]));
+                 }
+                 if (daily.temperature_2m_min && daily.temperature_2m_min.length > 0) {
+                     root.minTemp = convertTemp(parseFloat(daily.temperature_2m_min[0]));
                  }
  
-                 var raw = text.trim();
-                 if (raw.length > 0) {
-                     try {
-                         var data = JSON.parse(raw);
- 
-                         // Check for error from script
-                         if (data.error) {
-                             console.warn("WeatherService:", data.error);
-                             root.dataAvailable = false;
-                             root.handleError();
-                             return;
-                         }
- 
-                         if (data.current_weather && data.daily) {
-                             var weather = data.current_weather;
-                             var daily = data.daily;
- 
-                             root.weatherCode = parseInt(weather.weathercode);
-                             root.currentTemp = convertTemp(parseFloat(weather.temperature));
-                             root.windSpeed = parseFloat(weather.windspeed);
- 
-                             if (daily.temperature_2m_max && daily.temperature_2m_max.length > 0) {
-                                 root.maxTemp = convertTemp(parseFloat(daily.temperature_2m_max[0]));
-                             }
-                             if (daily.temperature_2m_min && daily.temperature_2m_min.length > 0) {
-                                 root.minTemp = convertTemp(parseFloat(daily.temperature_2m_min[0]));
-                             }
- 
-                             if (daily.sunrise && daily.sunrise.length > 0) {
-                                 root.sunrise = daily.sunrise[0].split("T")[1];
-                             }
-                             if (daily.sunset && daily.sunset.length > 0) {
-                                 root.sunset = daily.sunset[0].split("T")[1];
-                             }
- 
-                             // Parse 7-day forecast
-                             var forecastData = [];
-                             var dayCount = Math.min(7, daily.time ? daily.time.length : 0);
-                             for (var i = 0; i < dayCount; i++) {
-                                 // Manual date parse to avoid UTC midnight issues
-                                 // "YYYY-MM-DD"
-                                 var dateParts = daily.time[i].split("-");
-                                 var year = parseInt(dateParts[0]);
-                                 var month = parseInt(dateParts[1]) - 1; // 0-indexed months
-                                 var day = parseInt(dateParts[2]);
-                                 
-                                 var dayDate = new Date(year, month, day);
-                                 var dayName;
-                                 if (i === 0) {
-                                     dayName = I18n.t("weather.today");
-                                 } else {
-                                     var dayKeys = [
-                                         "calendar.day.sun", "calendar.day.mon", "calendar.day.tue",
-                                         "calendar.day.wed", "calendar.day.thu", "calendar.day.fri",
-                                         "calendar.day.sat"
-                                     ];
-                                     dayName = I18n.t(dayKeys[dayDate.getDay()]);
-                                 }
-                                 forecastData.push({
-                                     date: daily.time[i],
-                                     dayName: dayName,
-                                     weatherCode: daily.weathercode ? daily.weathercode[i] : 0,
-                                     emoji: getWeatherCodeEmoji(daily.weathercode ? daily.weathercode[i] : 0),
-                                     maxTemp: convertTemp(daily.temperature_2m_max ? daily.temperature_2m_max[i] : 0),
-                                     minTemp: convertTemp(daily.temperature_2m_min ? daily.temperature_2m_min[i] : 0)
-                                 });
-                             }
-                             root.forecast = forecastData;
- 
-                             root.weatherSymbol = getWeatherCodeEmoji(root.weatherCode);
-                             root.weatherDescription = getWeatherDescription(root.weatherCode);
-                             root.calculateSunPosition();
-                             root.dataAvailable = true;
-                             root.isLoading = false;
-                             root.hasFailed = false;
-                             root.retryCount = 0;
-                         } else {
-                             console.warn("WeatherService: Invalid response structure");
-                             root.dataAvailable = false;
-                             root.handleError();
-                         }
-                     } catch (e) {
-                         console.warn("WeatherService: JSON parse error:", e);
-                         root.dataAvailable = false;
-                         root.handleError();
-                     }
-                 } else {
-                     console.warn("WeatherService: Empty response");
-                     root.handleError();
+                 if (daily.sunrise && daily.sunrise.length > 0) {
+                     root.sunrise = String(daily.sunrise[0]).split("T")[1];
+                 }
+                 if (daily.sunset && daily.sunset.length > 0) {
+                     root.sunset = String(daily.sunset[0]).split("T")[1];
                  }
-             }
-         }
  
-         onExited: function (code) {
-             // SIGTERM (15) = intentional cancellation
-             if (code !== 0 && code !== 15) {
-                 console.warn("WeatherService: Script exited with code", code);
+                 // Parse 7-day forecast
+                 var forecastData = [];
+                 var dayCount = Math.min(7, daily.time ? daily.time.length : 0);
+                 for (var i = 0; i < dayCount; i++) {
+                     // Manual date parse to avoid UTC midnight issues
+                     // "YYYY-MM-DD"
+                     var dateParts = String(daily.time[i]).split("-");
+                     var year = parseInt(dateParts[0]);
+                     var month = parseInt(dateParts[1]) - 1; // 0-indexed months
+                     var day = parseInt(dateParts[2]);
+ 
+                     var dayDate = new Date(year, month, day);
 -                    var rawDayName = i === 0 ? "Today" : dayDate.toLocaleDateString(Qt.locale(), "ddd");
 -                    var dayName = rawDayName.charAt(0).toUpperCase() + rawDayName.slice(1);
++                    var dayName;
++                    if (i === 0) {
++                        dayName = I18n.t("weather.today");
++                    } else {
++                        var dayKeys = [
++                            "calendar.day.sun", "calendar.day.mon", "calendar.day.tue",
++                            "calendar.day.wed", "calendar.day.thu", "calendar.day.fri",
++                            "calendar.day.sat"
++                        ];
++                        dayName = I18n.t(dayKeys[dayDate.getDay()]);
++                    }
+                     forecastData.push({
+                         date: daily.time[i],
+                         dayName: dayName,
+                         weatherCode: daily.weathercode ? daily.weathercode[i] : 0,
+                         emoji: getWeatherCodeEmoji(daily.weathercode ? daily.weathercode[i] : 0),
+                         maxTemp: convertTemp(daily.temperature_2m_max ? daily.temperature_2m_max[i] : 0),
+                         minTemp: convertTemp(daily.temperature_2m_min ? daily.temperature_2m_min[i] : 0)
+                     });
+                 }
+                 root.forecast = forecastData;
+ 
+                 root.weatherSymbol = getWeatherCodeEmoji(root.weatherCode);
+                 root.weatherDescription = getWeatherDescription(root.weatherCode);
+                 root.calculateSunPosition();
+                 root.dataAvailable = true;
+                 root.isLoading = false;
+                 root.hasFailed = false;
+                 root.retryCount = 0;
+             } else {
+                 console.warn("WeatherService: Invalid response structure");
                  root.dataAvailable = false;
                  root.handleError();
              }
-             // Reset cancelled flag after process fully exits
-             root.wasCancelled = false;
+         } catch (e) {
+             console.warn("WeatherService: JSON parse error:", e);
+             root.dataAvailable = false;
+             root.handleError();
          }
      }
  
      // Watch for config changes
      property var weatherConfig: Config.weather
      readonly property string configLocation: weatherConfig ? weatherConfig.location : ""
      readonly property string configUnit: weatherConfig ? weatherConfig.unit : "C"
      property bool _initialized: false
  
      onConfigLocationChanged: {
diff --cc modules/tools/ScreenshotTool.qml
index be98cc82,f1ba4bda..47abb28b
--- a/modules/tools/ScreenshotTool.qml
+++ b/modules/tools/ScreenshotTool.qml
@@@ -68,35 -68,38 +68,38 @@@ PanelWindow 
          target: GlobalStates
          function onScreenshotCaptureModeChanged() {
              if (screenshotPopup.currentMode !== GlobalStates.screenshotCaptureMode) {
                  screenshotPopup.currentMode = GlobalStates.screenshotCaptureMode
              }
          }
      }
  
      property var activeWindows: []
  
+     // OCR/QR reuse this overlay restricted to plain area selection.
+     property bool regionOnly: Screenshot.captureMode === "ocr" || Screenshot.captureMode === "qr"
+ 
      property var modes: [
          {
              name: "region",
              icon: Icons.regionScreenshot,
 -            tooltip: "Region"
 +            tooltip: I18n.t("screenshot.region")
          },
          {
              name: "window",
              icon: Icons.windowScreenshot,
 -            tooltip: "Window"
 +            tooltip: I18n.t("screenshot.window")
          },
          {
              name: "screen",
              icon: Icons.fullScreenshot,
 -            tooltip: "Screen"
 +            tooltip: I18n.t("screenshot.screen")
          }
      ]
  
      function open() {
          if (modeGrid)
              modeGrid.currentIndex = 0;
          GlobalStates.screenshotCaptureMode = "region";
  
          screenshotPopup.state = "loading";
          
diff --cc modules/widgets/dashboard/Dashboard.qml
index 9761e7f7,6b60935c..6c1e633f
--- a/modules/widgets/dashboard/Dashboard.qml
+++ b/modules/widgets/dashboard/Dashboard.qml
@@@ -10,37 -10,28 +10,38 @@@ import qs.modules.notc
  import qs.modules.widgets.dashboard.widgets
  import qs.modules.widgets.dashboard.controls
  import qs.modules.widgets.dashboard.wallpapers
  import qs.modules.widgets.dashboard.metrics
  import qs.config
  
  NotchAnimationBehavior {
      id: root
  
      property int leftPanelWidth
+     property string screenName: ""
  
      property var state: QtObject {
          property int currentTab: GlobalStates.dashboardCurrentTab
      }
  
 -    readonly property var tabModel: [Icons.widgets, Icons.wallpapers, Icons.heartbeat]
 +    readonly property bool resourcesInDashboard: !(Config.system.resources && Config.system.resources.location === "bar")
 +    readonly property var tabModel: {
 +        let m = [Icons.widgets, Icons.wallpapers];
 +        if (root.resourcesInDashboard) m.push(Icons.heartbeat);
 +        return m;
 +    }
      readonly property int tabCount: tabModel.length
 +
 +    onResourcesInDashboardChanged: {
 +        if (!resourcesInDashboard && root.state.currentTab === 2)
 +            stack.navigateToTab(0);
 +    }
      readonly property int tabSpacing: 8
  
      readonly property int tabWidth: 48
      readonly property real nonAnimWidth: (state.currentTab === 0 ? 600 : 400) + tabWidth + 16 // unified launcher tab is wider
  
      implicitWidth: nonAnimWidth
      implicitHeight: 430
  
      // Track which tabs have been loaded (for lazy loading)
      property var loadedTabs: ({0: true}) // Tab 0 (widgets) loaded by default
diff --cc modules/widgets/dashboard/controls/SystemPanel.qml
index 11933d98,144db9b7..d343ab03
--- a/modules/widgets/dashboard/controls/SystemPanel.qml
+++ b/modules/widgets/dashboard/controls/SystemPanel.qml
@@@ -187,43 -116,43 +187,47 @@@ Item 
  
                      // ═══════════════════════════════════════════════════════════════
                      // MENU SECTION
                      // ═══════════════════════════════════════════════════════════════
                      ColumnLayout {
                          visible: root.currentSection === ""
                          Layout.fillWidth: true
                          spacing: 8
  
                          SectionButton {
 -                            text: "Prefixes"
 +                            text: I18n.t("settings.system.prefixes")
                              sectionId: "prefixes"
                          }
                          SectionButton {
 -                            text: "Weather"
 +                            text: I18n.t("settings.system.weather")
                              sectionId: "weather"
                          }
                          SectionButton {
 -                            text: "Performance"
 +                            text: I18n.t("settings.system.language")
 +                            sectionId: "language"
 +                        }
 +                        SectionButton {
 +                            text: I18n.t("settings.system.performance")
                              sectionId: "performance"
                          }
                          SectionButton {
 -                            text: "System Resources"
 +                            text: I18n.t("settings.system.resources")
                              sectionId: "system"
                          }
                          SectionButton {
 -                            text: "Idle"
 +                            text: I18n.t("settings.system.idle")
                              sectionId: "idle"
                          }
+                         SectionButton {
+                             text: "Terminal"
+                             sectionId: "terminal"
+                         }
                      }
  
                      // =====================
                      // PREFIX SECTION
                      // =====================
                      ColumnLayout {
                          visible: root.currentSection === "prefixes"
                          property string settingsSection: "prefixes"
                          Layout.fillWidth: true
                          spacing: 8
diff --cc modules/widgets/dashboard/widgets/QuickControls.qml
index b3c7e0b5,bc4a6acc..daf05a90
--- a/modules/widgets/dashboard/widgets/QuickControls.qml
+++ b/modules/widgets/dashboard/widgets/QuickControls.qml
@@@ -95,41 -95,41 +95,41 @@@ StyledRect 
                      }
                      onClicked: BluetoothService.toggle()
                      onRightClicked: root.togglePanel(1)
                      onLongPressed: root.togglePanel(1)
                  }
  
                  ControlButton {
                      Layout.preferredWidth: 48
                      Layout.preferredHeight: 48
                      iconName: Icons.nightLight
-                     isActive: NightLightService.active
-                     tooltipText: NightLightService.active ? I18n.t("controls.night_light_on") : I18n.t("controls.night_light_off")
-                     onClicked: NightLightService.toggle()
+                     isActive: NightLightClient.active
 -                    tooltipText: NightLightClient.active ? "Night Light: On" : "Night Light: Off"
++                    tooltipText: NightLightClient.active ? I18n.t("controls.night_light_on") : I18n.t("controls.night_light_off")
+                     onClicked: NightLightClient.toggle()
                  }
  
                  ControlButton {
                      Layout.preferredWidth: 48
                      Layout.preferredHeight: 48
                      iconName: Icons.caffeine
-                     isActive: CaffeineService.inhibit
-                     tooltipText: CaffeineService.inhibit ? I18n.t("controls.caffeine_on") : I18n.t("controls.caffeine_off")
-                     onClicked: CaffeineService.toggleInhibit()
+                     isActive: CaffeineClient.inhibit
 -                    tooltipText: CaffeineClient.inhibit ? "Caffeine: On" : "Caffeine: Off"
++                    tooltipText: CaffeineClient.inhibit ? I18n.t("controls.caffeine_on") : I18n.t("controls.caffeine_off")
+                     onClicked: CaffeineClient.toggle()
                  }
  
                  ControlButton {
                      Layout.preferredWidth: 48
                      Layout.preferredHeight: 48
                      iconName: Icons.gameMode
-                     isActive: GameModeService.toggled
-                     tooltipText: GameModeService.toggled ? I18n.t("controls.game_mode_on") : I18n.t("controls.game_mode_off")
-                     onClicked: GameModeService.toggle()
+                     isActive: GameModeClient.toggled
 -                    tooltipText: GameModeClient.toggled ? "Game Mode: On" : "Game Mode: Off"
++                    tooltipText: GameModeClient.toggled ? I18n.t("controls.game_mode_on") : I18n.t("controls.game_mode_off")
+                     onClicked: GameModeClient.toggle()
                  }
              }
          }
          
          Item {
              id: panelArea
              Layout.fillWidth: true
              Layout.preferredHeight: root.expandedPanel !== -1 ? root.width - 8 : 0 
              clip: true
              opacity: root.expandedPanel !== -1 ? 1 : 0
diff --cc modules/widgets/dashboard/widgets/calendar/Calendar.qml
index e39364fe,face38d4..27056c87
--- a/modules/widgets/dashboard/widgets/calendar/Calendar.qml
+++ b/modules/widgets/dashboard/widgets/calendar/Calendar.qml
@@@ -1,81 -1,47 +1,89 @@@
 +pragma ComponentBehavior: Bound
  import QtQuick
  import QtQuick.Layouts
 +import QtQuick.Controls
  import qs.modules.theme
  import qs.modules.components
 +import qs.modules.services
  import qs.config
 +import qs.modules.globals
  import "layout.js" as CalendarLayout
  
  Item {
      id: root
  
      property int monthShift: 0
-     property var viewingDate: CalendarLayout.getDateInXMonthsTime(monthShift)
+     property date currentDate: new Date()
+     property var viewingDate: CalendarLayout.getDateInXMonthsTime(monthShift, currentDate)
      property var calendarLayoutData: CalendarLayout.getCalendarLayout(viewingDate, monthShift === 0)
      property var calendarLayout: calendarLayoutData.calendar
      property int currentWeekRow: calendarLayoutData.currentWeekRow
      property int currentDayOfWeek: {
          if (monthShift !== 0)
              return -1;
-         var now = new Date();
-         return (now.getDay() + 6) % 7;
+         return (currentDate.getDay() + 6) % 7;
+     }
+ 
+     Timer {
+         interval: 60000
+         running: true
+         repeat: true
+         triggeredOnStart: true
+         onTriggered: root.currentDate = new Date()
      }
  
 -    // Helper function to get localized day abbreviation
 +    // Currently selected day for EventPopup
 +    property int selectedDay: 0
 +    property int selectedMonth: 0
 +    property int selectedYear: 0
 +    property var selectedDayEvents: []
 +
 +    // Viewing month/year for passing to day buttons
 +    readonly property int viewingMonth: viewingDate.getMonth() + 1
 +    readonly property int viewingYear: viewingDate.getFullYear()
 +
 +    signal openCalendarSettings()
 +    signal daySelected(int day, int month, int year)
 +
 +    function clearSelection() {
 +        selectedDay = 0;
 +        selectedMonth = 0;
 +        selectedYear = 0;
 +    }
 +
      function getDayAbbrev(dayIndex) {
 -        // Create a date for a known Monday (e.g., 2024-01-01 was a Monday)
 -        var d = new Date(2024, 0, 1 + dayIndex);
 -        var dayName = d.toLocaleDateString(Qt.locale(), "ddd");
 -        // Capitalize first letter and limit to 2 chars
 -        return (dayName.charAt(0).toUpperCase() + dayName.slice(1, 2)).replace(".", "");
 +        var keys = [
 +            "calendar.day.mon", "calendar.day.tue", "calendar.day.wed",
 +            "calendar.day.thu", "calendar.day.fri", "calendar.day.sat",
 +            "calendar.day.sun"
 +        ];
 +        return I18n.t(keys[dayIndex]);
 +    }
 +
 +    function openDayPopup(dayData, item) {
 +        const d = parseInt(dayData.day);
 +        if (isNaN(d)) return;
 +        // Determine actual month/year for this day cell
 +        let m = root.viewingMonth;
 +        let y = root.viewingYear;
 +        if (dayData.today === -1) {
 +            // Day from adjacent month — not current viewing month
 +            if (d > 15) { m--; } else { m++; }
 +            if (m < 1) { m = 12; y--; }
 +            if (m > 12) { m = 1; y++; }
 +        }
 +        root.selectedDay = d;
 +        root.selectedMonth = m;
 +        root.selectedYear = y;
 +        root.selectedDayEvents = CalendarService.eventsForDate(y, m, d);
 +        root.daySelected(d, m, y);
      }
  
      ColumnLayout {
          anchors.fill: parent
          spacing: 0
  
          StyledRect {
              id: calendarPane
              variant: "pane"
              Layout.fillWidth: true
diff --cc modules/widgets/tools/ToolsMenu.qml
index 66457c01,2e820c06..2a2381ed
--- a/modules/widgets/tools/ToolsMenu.qml
+++ b/modules/widgets/tools/ToolsMenu.qml
@@@ -23,151 -22,119 +22,119 @@@ ActionGrid 
      }
  
      layout: "row"
      buttonSize: 48
      iconSize: 20
      spacing: 8
  
      actions: [
          {
              icon: Icons.camera,
 -            tooltip: "Screenshot",
 +            tooltip: I18n.t("tools.screenshot"),
              command: ""
          },
          {
              icon: Icons.screenshots,
 -            tooltip: "Open Screenshots",
 +            tooltip: I18n.t("tools.screenshot_directory"),
              command: ""
          },
          {
              type: "separator"
          },
          recordAction,
          {
              icon: Icons.recordings,
 -            tooltip: "Open Recordings",
 +            tooltip: I18n.t("tools.screenrecord_directory"),
              command: ""
          },
          {
              type: "separator"
          },
          {
              icon: Icons.picker,
 -            tooltip: "Color Picker",
 +            tooltip: I18n.t("tools.color_picker"),
              command: ""
          },
          {
              icon: Icons.textT,
 -            tooltip: "OCR",
 +            tooltip: I18n.t("tools.ocr"),
              command: ""
          },
          {
              icon: Icons.qrCode,
 -            tooltip: "QR Code",
 +            tooltip: I18n.t("tools.qr"),
              command: ""
          },
          {
              icon: Icons.google,
 -            tooltip: "Google Lens",
 +            tooltip: I18n.t("tools.google_lens"),
              command: ""
          },
          {
              icon: GlobalStates.mirrorWindowVisible ? Icons.webcamSlash : Icons.webcam,
 -            tooltip: "Mirror",
 +            tooltip: I18n.t("tools.mirror"),
              command: ""
          }
      ]
  
      Process {
          id: colorPickerProc
      }
  
-     Process {
-         id: ocrProc
-     }
- 
-     Process {
-         id: qrProc
-     }
- 
      Process {
          id: openFolderProc
          // Usamos nohup para desvincular el proceso de visualización de carpetas
          command: ["bash", "-c", "nohup xdg-open \"$0\" > /dev/null 2>&1 &"]
      }
  
      onActionTriggered: action => {
          console.log("Tools action triggered:", action.tooltip);
  
 -        if (action.tooltip === "Screenshot") {
 +        if (action.tooltip === I18n.t("tools.screenshot")) {
              Screenshot.initialize();
              GlobalStates.screenshotToolVisible = true;
              root.itemSelected();
 -        } else if (action.tooltip === "Screen Recorder") {
 +        } else if (action.tooltip === I18n.t("tools.screenrecord_start")) {
              ScreenRecorder.initialize();
              GlobalStates.screenRecordToolVisible = true;
              root.itemSelected();
 -        } else if (action.tooltip === "Stop Recording") {
 +        } else if (action.tooltip === I18n.t("tools.screenrecord_stop")) {
              ScreenRecorder.toggleRecording();
              root.itemSelected();
 -        } else if (action.tooltip === "Open Screenshots") {
 +        } else if (action.tooltip === I18n.t("tools.screenshot_directory")) {
-             // Usamos xdg-user-dir en el comando bash para respetar las rutas del sistema
-             var cmd = "dir=\"$(xdg-user-dir PICTURES)/Screenshots\"; mkdir -p \"$dir\"; nohup xdg-open \"$dir\" > /dev/null 2>&1 &";
-             
-             openFolderProc.command = ["bash", "-c", cmd];
+             Screenshot.initialize();
+             var shotsDir = Screenshot.screenshotsDir !== "" ? Screenshot.screenshotsDir : Quickshell.env("HOME") + "/Pictures/Screenshots";
+             openFolderProc.command = ["bash", "-c", "nohup xdg-open \"$0\" > /dev/null 2>&1 &", shotsDir];
              openFolderProc.running = true;
-             
+ 
              root.itemSelected();
 -        } else if (action.tooltip === "Open Recordings") {
 +        } else if (action.tooltip === I18n.t("tools.screenrecord_directory")) {
-             // Usamos xdg-user-dir para videos, manteniendo la subcarpeta Recordings
-             var cmd = "dir=\"$(xdg-user-dir VIDEOS)/Recordings\"; mkdir -p \"$dir\"; nohup xdg-open \"$dir\" > /dev/null 2>&1 &";
-             
-             openFolderProc.command = ["bash", "-c", cmd];
+             ScreenRecorder.initialize();
+             var recsDir = ScreenRecorder.videosDir !== "" ? ScreenRecorder.videosDir : Quickshell.env("HOME") + "/Videos/Recordings";
+             openFolderProc.command = ["bash", "-c", "nohup xdg-open \"$0\" > /dev/null 2>&1 &", recsDir];
              openFolderProc.running = true;
-             
+ 
               root.itemSelected();
 -        } else if (action.tooltip === "Color Picker") {
 +        } else if (action.tooltip === I18n.t("tools.color_picker")) {
-             var scriptPath = Qt.resolvedUrl("../../../scripts/colorpicker.py").toString().replace("file://", "");
              // Run detached so it survives when the menu closes
-             colorPickerProc.command = ["bash", "-c", "nohup python3 \"" + scriptPath + "\" > /dev/null 2>&1 &"];
+             colorPickerProc.command = ["bash", "-c", "nohup ambxst colorpicker > /dev/null 2>&1 &"];
              colorPickerProc.running = true;
              root.itemSelected();
 -        } else if (action.tooltip === "OCR") {
 +        } else if (action.tooltip === I18n.t("tools.ocr")) {
-             var scriptPath = Qt.resolvedUrl("../../../scripts/ocr.sh").toString().replace("file://", "");
-             
-             // Build languages string from Config
-             var ocrConfig = Config.system.ocr;
-             var langs = [];
-             
-             if (ocrConfig) {
-                 if (ocrConfig.eng !== false) langs.push("eng"); // Default true
-                 if (ocrConfig.spa !== false) langs.push("spa"); // Default true
-                 if (ocrConfig.lat === true) langs.push("lat");
-                 if (ocrConfig.jpn === true) langs.push("jpn");
-                 if (ocrConfig.chi_sim === true) langs.push("chi_sim");
-                 if (ocrConfig.chi_tra === true) langs.push("chi_tra");
-                 if (ocrConfig.kor === true) langs.push("kor");
-                 if (ocrConfig.rus === true) langs.push("rus");
-             } else {
-                 langs = ["eng", "spa"];
-             }
-             
-             if (langs.length === 0) langs.push("eng");
-             var langString = langs.join("+");
- 
-             ocrProc.command = ["bash", "-c", "nohup \"" + scriptPath + "\" \"" + langString + "\" > /dev/null 2>&1 &"];
-             ocrProc.running = true;
+             Screenshot.initialize();
+             Screenshot.captureMode = "ocr";
+             GlobalStates.screenshotToolVisible = true;
              root.itemSelected();
 -        } else if (action.tooltip === "QR Code") {
 +        } else if (action.tooltip === I18n.t("tools.qr")) {
-             var scriptPath = Qt.resolvedUrl("../../../scripts/qr_scan.sh").toString().replace("file://", "");
-             qrProc.command = ["bash", "-c", "nohup \"" + scriptPath + "\" > /dev/null 2>&1 &"];
-             qrProc.running = true;
+             Screenshot.initialize();
+             Screenshot.captureMode = "qr";
+             GlobalStates.screenshotToolVisible = true;
              root.itemSelected();
 -        } else if (action.tooltip === "Google Lens") {
 +        } else if (action.tooltip === I18n.t("tools.google_lens")) {
              Screenshot.captureMode = "lens";
              GlobalStates.screenshotToolVisible = true;
              root.itemSelected();
 -        } else if (action.tooltip === "Mirror") {
 +        } else if (action.tooltip === I18n.t("tools.mirror")) {
              GlobalStates.mirrorWindowVisible = !GlobalStates.mirrorWindowVisible;
          }
      }
  }
