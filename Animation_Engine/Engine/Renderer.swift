import MetalKit

class Renderer: NSObject {
    public static var AspectRatio: Float = 0.0
    
    var vertexDescriptor: MTLVertexDescriptor!
    var renderPipelineState: MTLRenderPipelineState!
    var depthStencilState: MTLDepthStencilState!
    var samplerState: MTLSamplerState!
    
    var scene: Scene!
    
    override init() {
        super.init()
        
        initializeVertexDescriptor()
        
        initializeDepthStencilState()
        
        initializeSamplerState()
        
        initializeRenderPipelineState()
        
        initializeScene()
    }
    
    private func initializeVertexDescriptor() {
        vertexDescriptor = MTLVertexDescriptor()
        
        //Position
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0
        
        //Normal
        vertexDescriptor.attributes[1].format = .float3
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[1].offset = float3.size
        
        //Joint Indices
        vertexDescriptor.attributes[2].format = .int3
        vertexDescriptor.attributes[2].bufferIndex = 0
        vertexDescriptor.attributes[2].offset = float3.size + float3.size
        
        //Weights
        vertexDescriptor.attributes[3].format = .float3
        vertexDescriptor.attributes[3].bufferIndex = 0
        vertexDescriptor.attributes[3].offset = float3.size + float3.size + int3.size
        
        //Texture Coords
        vertexDescriptor.attributes[4].format = .float2
        vertexDescriptor.attributes[4].bufferIndex = 0
        vertexDescriptor.attributes[4].offset = float3.size + float3.size + int3.size + float3.size
        
        vertexDescriptor.layouts[0].stride = Vertex.stride
    }
    
    private func initializeRenderPipelineState(){
        let library = Engine.Device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "animation_vertex_shader")
        let fragmentFunction = library?.makeFunction(name: "animation_fragment_shader")
        
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        renderPipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        
        do {
            renderPipelineState = try Engine.Device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch {
            print(error)
        }
    }
    
    private func initializeDepthStencilState(){
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilState = Engine.Device.makeDepthStencilState(descriptor: depthStencilDescriptor)!
    }
    
    private func initializeSamplerState() {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.compareFunction = .less
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerState = Engine.Device.makeSamplerState(descriptor: samplerDescriptor)!
    }
    
    private func initializeScene(){
        scene = Scene()
    }
}

extension Renderer: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        Renderer.AspectRatio = Float(size.width) / Float(size.height)
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable, let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        
        let commandBuffer = Engine.CommandQueue.makeCommandBuffer()
        let renderCommandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderCommandEncoder?.setRenderPipelineState(renderPipelineState)
        renderCommandEncoder?.setDepthStencilState(depthStencilState)
        renderCommandEncoder?.setFragmentSamplerState(samplerState, index: 0)
        
        let deltaTime = 1 / Float(view.preferredFramesPerSecond)
        
        scene.update(deltaTime)
        
        scene.render(renderCommandEncoder!)
        
        renderCommandEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
    
}
