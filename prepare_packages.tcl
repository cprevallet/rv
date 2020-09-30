# Identify and load the dependent packages in an OS specific manner.
# Separate the boilerplate here so that it may be reused.
# from tklib
package require tablelist_tile
# from tcllib
package require fileutil
package require csv
package require units

package require tkblt
# requires tcl > 8
namespace import blt::*
# custom package provided by this application
package require fit
