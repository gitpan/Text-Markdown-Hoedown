#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#ifdef __cplusplus
} /* extern "C" */
#endif

#include <string.h>

#define NEED_newSVpvn_flags
#include "ppport.h"

#include "../../hoedown/src/markdown.h"
#include "../../hoedown/src/html.h"

#define XS_STRUCT2OBJ(sv, class, obj) \
    sv = newSViv(PTR2IV(obj));  \
    sv = newRV_noinc(sv); \
    sv_bless(sv, gv_stashpv(class, 1)); \
    SvREADONLY_on(sv);

#define CONST(name) \
    newCONSTSUB(stash, #name, newSViv(name)); \
    av_push(get_av("Text::Markdown::Hoedown::EXPORT", GV_ADD), newSVpv(#name, 0));

typedef enum {
    TMH_CALLBACK_TYPE_HTML,
    TMH_CALLBACK_TYPE_CUSTOM
} tmh_callback_type;

typedef struct {
    tmh_callback_type type;
    struct hoedown_callbacks callbacks;
    union {
        struct hoedown_html_renderopt* html_opaque;
        HV * custom_opaque;
    };
} tmh_callbacks;

typedef void* hoedown_opaque_t;

#define PUSHBUF(text) \
    if (text) { \
        mXPUSHp(text->data, text->size); \
    } else { \
        XPUSHs(&PL_sv_undef); \
    }

#define CB_HEADER(key) \
    dTHX; dSP; bool is_null = 0; \
    SV** rcb = hv_fetch((HV*)opaque, key, strlen(key), 0); \
    if (!rcb) { return; } \
    SV* cb = *rcb; \
    \
    ENTER; \
    SAVETMPS; \
    \
    PUSHMARK(SP);

#define CB_FOOTER \
    PUTBACK; \
    \
    int count = call_sv(cb, G_SCALAR); \
    \
    SPAGAIN; \
    \
    if (count == 1) { \
        SV* ret = POPs; \
        if (ret != &PL_sv_undef) { \
            STRLEN l; \
            char * p = SvPV(ret, l); \
            hoedown_buffer_grow(ob, ob->size + l); \
            hoedown_buffer_put(ob, p, l); \
        } else {\
            is_null = 1;\
        } \
    } \
    \
    PUTBACK; \
    FREETMPS; \
    LEAVE;


#include "gen.callback.c"

MODULE = Text::Markdown::Hoedown    PACKAGE = Text::Markdown::Hoedown PREFIX=hoedown_markdown_

BOOT:
    HV* stash = gv_stashpv("Text::Markdown::Hoedown", GV_ADD);

    CONST(HOEDOWN_EXT_NO_INTRA_EMPHASIS);
    CONST(HOEDOWN_EXT_TABLES);
    CONST(HOEDOWN_EXT_FENCED_CODE);
    CONST(HOEDOWN_EXT_AUTOLINK);
    CONST(HOEDOWN_EXT_STRIKETHROUGH);
    CONST(HOEDOWN_EXT_UNDERLINE);
    CONST(HOEDOWN_EXT_SPACE_HEADERS);
    CONST(HOEDOWN_EXT_SUPERSCRIPT);
    CONST(HOEDOWN_EXT_LAX_SPACING);
    CONST(HOEDOWN_EXT_DISABLE_INDENTED_CODE);
    CONST(HOEDOWN_EXT_HIGHLIGHT);
    CONST(HOEDOWN_EXT_FOOTNOTES);
    CONST(HOEDOWN_EXT_QUOTE);

    CONST(HOEDOWN_HTML_SKIP_HTML);
    CONST(HOEDOWN_HTML_SKIP_STYLE);
    CONST(HOEDOWN_HTML_SKIP_IMAGES);
    CONST(HOEDOWN_HTML_SKIP_LINKS);
    CONST(HOEDOWN_HTML_EXPAND_TABS);
    CONST(HOEDOWN_HTML_SAFELINK);
    CONST(HOEDOWN_HTML_TOC);
    CONST(HOEDOWN_HTML_HARD_WRAP);
    CONST(HOEDOWN_HTML_USE_XHTML);
    CONST(HOEDOWN_HTML_ESCAPE);
    CONST(HOEDOWN_HTML_PRETTIFY);

TYPEMAP: <<HERE

struct hoedown_markdown * T_HOEDOWN_MARKDOWN
struct hoedown_buffer* T_HOEDOWN_BUFFER
struct hoedown_callbacks* T_HOEDOWN_CALLBACKS
tmh_callbacks* T_TMH_CALLBACKS
const struct hoedown_callbacks* T_HOEDOWN_CALLBACKS
struct hoedown_html_renderopt* T_HOEDOWN_HTML_RENDEROPT
hoedown_opaque_t T_HOEDOWN_OPAQUE_T

OUTPUT

T_TMH_CALLBACKS
    sv_setref_pv($arg, \"Text::Markdown::Hoedown::Callbacks\", (void*)$var);

T_HOEDOWN_OPAQUE_T
    sv_setref_pv($arg, \"Text::Markdown::Hoedown::Opaque\", (void*)$var);

T_HOEDOWN_HTML_RENDEROPT
    sv_setref_pv($arg, \"Text::Markdown::Hoedown::HTMLRenderOpt\", (void*)$var);

T_HOEDOWN_CALLBACKS
    sv_setref_pv($arg, \"Text::Markdown::Hoedown::Callbacks\", (void*)$var);

T_HOEDOWN_MARKDOWN
    sv_setref_pv($arg, \"Text::Markdown::Hoedown::Markdown\", (void*)$var);

T_HOEDOWN_BUFFER
    sv_setref_pv($arg, \"Text::Markdown::Hoedown::Buffer\", (void*)$var);

INPUT

T_TMH_CALLBACKS
    $var = INT2PTR($type, SvROK($arg) ? SvIV(SvRV($arg)) : SvIV($arg));

T_HOEDOWN_OPAQUE_T
    $var = INT2PTR($type, SvROK($arg) ? SvIV(SvRV($arg)) : SvIV($arg));

T_HOEDOWN_HTML_RENDEROPT
    $var = INT2PTR($type, SvROK($arg) ? SvIV(SvRV($arg)) : SvIV($arg));

T_HOEDOWN_CALLBACKS
    $var = INT2PTR($type, SvROK($arg) ? SvIV(SvRV($arg)) : SvIV($arg));

T_HOEDOWN_BUFFER
    $var = INT2PTR($type, SvROK($arg) ? SvIV(SvRV($arg)) : SvIV($arg));

T_HOEDOWN_MARKDOWN
    $var = INT2PTR($type, SvROK($arg) ? SvIV(SvRV($arg)) : SvIV($arg));

HERE

PROTOTYPES: DISABLE

MODULE = Text::Markdown::Hoedown    PACKAGE = Text::Markdown::Hoedown::Markdown PREFIX=hoedown_markdown_

struct hoedown_markdown *
hoedown_markdown_new(const char* klass, unsigned int extensions, size_t max_nesting, tmh_callbacks*callbacks)
CODE:
    if (callbacks->type == TMH_CALLBACK_TYPE_HTML) {
        RETVAL = hoedown_markdown_new(extensions, max_nesting, &(callbacks->callbacks), callbacks->html_opaque);
    } else {
        RETVAL = hoedown_markdown_new(extensions, max_nesting, &(callbacks->callbacks), callbacks->custom_opaque);
    }
OUTPUT:
    RETVAL

SV*
hoedown_markdown_render(struct hoedown_markdown *self, SV *src_sv)
PREINIT:
    struct hoedown_buffer* ob;
    const char *src;
    STRLEN src_len;
CODE:
    ob = hoedown_buffer_new(64);

    src = SvPV(src_sv, src_len);
    hoedown_markdown_render(ob, src, src_len, self);

    SV* ret = newSVpv(hoedown_buffer_cstr(ob), 0);
    if (SvUTF8(src_sv)) {
        SvUTF8_on(ret);
    }
    hoedown_buffer_free(ob);
    RETVAL = ret;
OUTPUT:
    RETVAL

void
DESTROY(struct hoedown_markdown*self)
CODE:
    hoedown_markdown_free(self);

MODULE = Text::Markdown::Hoedown    PACKAGE = Text::Markdown::Hoedown::Callbacks

tmh_callbacks*
new(const char*CLASS)
PREINIT:
    tmh_callbacks* self;
CODE:
    Newxz(self, 1, tmh_callbacks);
    self->type = TMH_CALLBACK_TYPE_CUSTOM;
    self->custom_opaque = newHV();
    RETVAL = self;
OUTPUT:
    RETVAL

INCLUDE: gen.callback.inc

tmh_callbacks*
html_renderer(const char *klass, unsigned int render_flags)
PREINIT:
    tmh_callbacks* self;
CODE:
    Newxz(self, 1, tmh_callbacks);
    Newxz(self->html_opaque, 1, struct hoedown_html_renderopt);
    self->type = TMH_CALLBACK_TYPE_HTML;

    hoedown_html_renderer(&(self->callbacks), self->html_opaque, render_flags);
    /* hoedown should provide API for setting nesting_level. But it doesn't provide. */
    self->html_opaque->toc_data.nesting_level = 99;
    RETVAL = self;
OUTPUT:
    RETVAL

tmh_callbacks*
html_toc_renderer(const char* klass, int nesting_level)
PREINIT:
    tmh_callbacks* self;
CODE:
    Newxz(self, 1, tmh_callbacks);
    Newxz(self->html_opaque, 1, struct hoedown_html_renderopt);
    self->type = TMH_CALLBACK_TYPE_HTML;

    hoedown_html_toc_renderer(&(self->callbacks), self->html_opaque, nesting_level);

    RETVAL = self;
OUTPUT:
    RETVAL

void
DESTROY(tmh_callbacks* self)
CODE:
    if (self->type == TMH_CALLBACK_TYPE_CUSTOM) {
        SvREFCNT_dec(self->custom_opaque);
    } else {
        Safefree(self->html_opaque);
    }
    Safefree(self);

MODULE = Text::Markdown::Hoedown    PACKAGE = Text::Markdown::Hoedown::Buffer PREFIX=hoedown_buffer_

struct hoedown_buffer*
hoedown_buffer_new(size_t size)

int
hoedown_buffer_grow(struct hoedown_buffer* self, size_t size)

void
hoedown_buffer_put(struct hoedown_buffer* self, const char*str, size_t length(str))

void
DESTROY(struct hoedown_buffer*self)
CODE:
    hoedown_buffer_free(self);

