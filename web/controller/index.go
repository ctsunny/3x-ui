package controller

import (
	"net/http"

	"github.com/mhsanaei/3x-ui/v2/web/service"
	"github.com/mhsanaei/3x-ui/v2/web/session"

	"github.com/gin-gonic/gin"
)

// IndexController handles the main index route.
type IndexController struct {
	BaseController
	settingService service.SettingService
}

// NewIndexController creates a new IndexController and initializes its routes.
func NewIndexController(g *gin.RouterGroup) *IndexController {
	a := &IndexController{}
	a.initRouter(g)
	return a
}

// initRouter sets up the routes for the index page.
func (a *IndexController) initRouter(g *gin.RouterGroup) {
	g.GET("/", a.index)
}

// index handles the root route, redirecting logged-in users to the panel or showing the login page.
func (a *IndexController) index(c *gin.Context) {
	if session.IsLogin(c) {
		c.Redirect(http.StatusTemporaryRedirect, "panel/")
		return
	}
	disguise, _ := a.settingService.GetDisguiseLoginPage()
	if disguise {
		html(c, "login/login_disguise.html", "Web Management Console", nil)
		return
	}
	html(c, "login/login.html", "pages.login.title", nil)
}
